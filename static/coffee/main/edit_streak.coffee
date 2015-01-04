
class S.EditStreak
  constructor: (el, @opts={}) ->
    @el = $ el
    @el.find(".date_picker").datepicker()
    @setup_timezone()

    S.redactor @el.find "textarea"

  setup_timezone: =>
    @el.find(".timezone_input").val jstz.determine().name()

    if @opts.streak.hour_offset?
      hour_offset_input = @el.find ".hour_offset_input"
      tz_offset = new Date().getTimezoneOffset()/60
      hour_offset_input.val tz_offset + @opts.streak.hour_offset

