db = require "lapis.db"
import Model from require "lapis.db.model"

class Submissions extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @preload_streaks: (submissions) =>
    import StreakSubmissions, Streaks from require "models"

    submission_ids = [s.id for s in *submissions]
    streak_submits = StreakSubmissions\find_all submission_ids, {
      key: "submission_id"
    }

    Streaks\include_in streak_submits, "streak_id"

    s_by_s_id = {}
    for submit in *streak_submits
      s_by_s_id[submit.submission_id] or= {}
      table.insert s_by_s_id[submit.submission_id], submit.streak

    for submission in *submissions
      submission.streaks = s_by_s_id[submission.id] or {}

    submissions, [s.streak for s in *streak_submits]

  allowed_to_view: (user) =>
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  get_streaks: =>
    unless @streaks
      import StreakSubmissions, Streaks from require "models"
      submits = StreakSubmissions\select "where submission_id = ?", @id
      Streaks\include_in submits, "streak_id"
      @streaks = [s.streak for s in *submits]

    @streaks

  get_uploads: =>
    unless @uploads
      import Uploads from require "models"
      @uploads = Uploads\select "
        where object_type = ? and object_id = ? and ready
        order by position
      ", Uploads.object_types.submission, @id

    @uploads

  url_params: =>
    "view_submission", id: @id

