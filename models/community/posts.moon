
db = require "lapis.db"

class Posts extends require "community.models.posts"
  url_params: =>
    if @is_topic_post! and not @get_topic!.permanent
      @get_topic!\url_params!
    else
      "community.post", post_id: @id

  in_topic_url_params: (r) =>
    import POSTS_PER_PAGE from require "community.limits"

    topic = @get_topic!
    route, url_params, params = topic\url_params!
    root = @get_root_ancestor! or @
    offset = math.floor((root.post_number - 1) / POSTS_PER_PAGE) * POSTS_PER_PAGE

    if offset > 0
      params or={}
      params.after = offset

    nil, r\build_url r\url_for(route, url_params, params), {
      fragment: "post-#{@id}"
    }

  send_notifications: =>
    import Notifications from require "models"


    for {kind, user, object, related_object} in *@notification_targets!
      notification_type = "community_#{kind}"
      continue unless Notifications.types[notification_type]
      target = object or @
      associated = related_object or object and @ or nil
      Notifications\notify_for user, target, notification_type, associated
