
import to_json from require "lapis.util"
date = require "date"

import Streaks from require "models"

class EditStreak extends require "widgets.base"
  @include "widgets.form_helpers"

  js_init: =>
    opts = {
      streak: {
        hour_offset: @streak and @streak.hour_offset
      }
    }
    "new S.EditStreak(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    @content_for "all_js", ->
      @include_jquery_ui!
      @include_redactor!

    div class: "page_header", ->
      if @streak
        h2 "Edit streak"
      else
        h2 "New streak"

    @render_errors!

    streak = @params.streak or @streak or {}

    form method: "post", class: "form primary_form", ->
      @csrf_input!
      input type: "hidden", name: "timezone", value: "", class: "timezone_input"

      @text_input_row {
        label: "Title"
        name: "streak[title]"
        value: streak.title
      }

      @text_input_row {
        label: "Short description"
        sub: "A single line describing the streak"
        name: "streak[short_description]"
        value: streak.short_description
      }

      @text_input_row {
        type: "textarea"
        label: "Description"
        name: "streak[description]"
        value: streak.description
      }

      @input_row "Interval", ->
        @radio_buttons "streak[rate]", {
          {"daily", "Daily", "Submissions due every day"}
          {"weekly", "Weekly", "Submissions due every 7 days"}
        }, streak.rate and Streaks.rates[streak.rate] or "daily"

      div class: "input_row duration_row", ->
        div class: "label", ->
          text "Duration"
          span class: "sub", ->
            raw " &mdash; When does the streak start and stop"

        div class: "date_row", ->
          label ->
            div class: "duration_label label", "Start date:"
            input {
              type: "text"
              class: "date_picker start_date"
              name: "streak[start_date]"
              readonly: "readonly"
              value: @format_date_for_input streak.start_date
            }

        div class: "date_row", ->
          label ->
            div class: "duration_label label", "End date:"
            input {
              type: "text"
              class: "date_picker end_date"
              name: "streak[end_date]"
              readonly: "readonly"
              value: @format_date_for_input streak.end_date
            }

          span class: "duration_summary"

      @text_input_row {
        label: "Roll over hour"
        sub: "Hour in day when streak rolls over to next day"
        name: "streak[hour_offset]"
        class: "hour_offset_input"
        value: ""

        between: ->
          p class: "input_full_directions", ->
            text "Leave this at 0 to have each submission due at midnight. If you
            want the deadline to be 4am you could set it to "
            code "4"
            text ". If you want the deadline to be 10pm you could set it to"
            code "-2"
            text ". Integers only."
      }

      div id: "publish_status"
      @input_row "Publish", ->
        @radio_buttons "streak[publish_status]", {
          {"draft", "Draft", "Only you can see the streak"}
          {"published", "Published", "Streak is public"}
          {"hidden", "Hidden", "Only people with the URL can participate in the streak"}
        }, streak.publish_status and Streaks.publish_statuses\to_name(streak.publish_status) or "draft"

      div class: "button_row", ->
        button class: "button", "Save"

  format_date_for_input: (timestamp) =>
    return unless timestamp
    date(timestamp)\fmt "%m/%d/%Y"

