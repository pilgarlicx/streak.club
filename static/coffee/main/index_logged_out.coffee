
class S.IndexLoggedOut
  constructor: (el) ->
    @el = $ el

    new S.Countdown @el.find(".countdown"), moment().add(6, "hour").add(32, "minute")

    grid = @el.find ".streak_grid"
    win = $(window)
    win.on "scroll.show_grid", =>
      if win.scrollTop() + win.height() / 3 > grid.offset().top
        @fill_grid()
        win.off "scroll.show_grid"

    @el.find(".slide_up").removeClass "slide_up"

    setTimeout =>
      @el.find(".typed_drop").typed {
        typeSpeed: 20
        backDelay: 1000
        strings: [
          "staying motivated"
          "making art"
          "writing stories"
          "composing songs"
          "creative streaks"
        ]
      }
    , 200

  fill_grid: ->
    grid = @el.find ".streak_grid"
    boxes = grid.find ".grid_box"
    value = grid.find ".stat_value"

    count = 0
    for b, i in boxes
      do (b) ->
        setTimeout =>
          $(b).addClass "active"
          count += 1
          value.text "#{count}"
        , Math.pow(i, 1.14) * 40



