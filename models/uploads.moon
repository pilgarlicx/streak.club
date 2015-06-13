db = require "lapis.db"
import Model, enum from require "lapis.db.model"

config = require("lapis.config").get!

import thumb from require "helpers.images"

class Uploads extends Model
  @timestamp: true

  @types: enum {
    image: 1
    file: 2
  }

  @object_types: enum {
    submission: 1
  }

  @storage_types: enum {
    filesystem: 1
    google_cloud_storage: 2
  }

  @content_types = {
    jpg: "image/jpeg"
    jpeg: "image/jpeg"
    png: "image/png"
    gif: "image/gif"
  }

  @preload_objects: (objects) =>
    ids_by_type = {}
    for object in *objects
      object_type = @object_type_for_object object
      ids_by_type[object_type] or= {}
      table.insert ids_by_type[object_type], object.id

    for object_type, ids in pairs ids_by_type
      uploads = @find_all ids, key: "object_id", where: {
        ready: true
        :object_type
      }

      uploads_by_object_id = {}
      for upload in *uploads
        uploads_by_object_id[upload.object_id] or= {}
        table.insert uploads_by_object_id[upload.object_id], upload

      for _, upload_list in pairs uploads_by_object_id
        table.sort upload_list, (a,b) ->
          a.position < b.position

      for object in *objects
        continue unless @object_type_for_object(object) == object_type
        object.uploads = uploads_by_object_id[object.id]

    true

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "Submissions"
        @object_types.submission
      else
        error "unknown object (#{object.__class.__name})"

  @use_google_cloud_storage: =>
    -- if we have secret and storage
    local storage
    pcall ->
      storage = require "secret.storage"

    bucket = require("lapis.config").get!.storage_bucket
    storage and bucket

  @create: (opts={}) =>
    assert opts.user_id, "missing user id"
    assert opts.filename, "missing file name"

    opts.extension or= opts.filename\match ".%.([%w_]+)$"
    opts.extension = opts.extension\lower! if opts.extension

    unless opts.extension
      return nil, "missing extensions"

    opts.type = if @content_types[opts.extension]
      "image"
    else
      "file"

    opts.type = @types\for_db opts.type

    opts.storage_type = if @use_google_cloud_storage!
      @storage_types.google_cloud_storage
    else
      @storage_types.filesystem

    Model.create @, opts

  allowed_to_download: (user) =>
    return false if @is_image!
    true

  allowed_to_edit: (user) =>
    return nil unless user
    return true if user\is_admin!
    user.id == @user_id

  belongs_to_object: (object) =>
    return false unless object.id == @object_id
    @@object_type_for_object(object) == @object_type

  path: =>
    "uploads/#{@@types[@type]}/#{@id}.#{@extension}"

  short_path: =>
    "#{@@types[@type]}/#{@id}.#{@extension}"

  is_image: =>
    @type == @@types.image

  is_audio: =>
    @extension == "mp3"

  is_filesystem: =>
    @storage_type == @@storage_types.filesystem

  is_google_cloud_storage: =>
    @storage_type == @@storage_types.google_cloud_storage

  image_url: (size="original") =>
    assert @is_image!, "upload not image"
    thumb @path!, size

  save_url: (req) =>
    if @is_google_cloud_storage!
      req\url_for "save_upload", id: @id

  bucket_key: =>
    if @is_google_cloud_storage!
      @path!

  upload_url_and_params: (req) =>
    switch @storage_type
      when @@storage_types.filesystem
        import signed_url from require "helpers.url"
        url = signed_url req\url_for("receive_upload", id: @id)
        url, {}
      when @@storage_types.google_cloud_storage
        storage = require "secret.storage"
        bucket = assert require("lapis.config").get!.storage_bucket, "missing bucket"
        storage\upload_url bucket, @bucket_key!, {
          size_limit: 20 * 1024^3
        }
      else
        error "unknown storage type"

  url_params: (_, ...) =>
    switch @type
      when @@types.image
        error "implement image url" unless @storage_type == @@storage_types.filesystem
        nil, @image_url ...
      else
        expires = ... or 15
        expire = os.time! + expires

        switch @storage_type
          when @@storage_types.filesystem
            import signed_url from require "helpers.url"
            nil, signed_url "/download/#{@short_path!}?expires=#{expire}"

          when @@storage_types.google_cloud_storage
            storage = require "secret.storage"
            bucket = require("lapis.config").get!.storage_bucket
            nil, storage\signed_url bucket, @bucket_key!, expire

  delete: =>
    with super!
      return true unless @ready

      switch @storage_type
        when @@storage_types.filesystem
          import shell_quote, exec from require "helpers.shell"
          exec "rm #{shell_quote "#{config.user_content_path}/#{@path!}"}"
        when @@storage_types.google_cloud_storage
          storage = require "secret.storage"
          bucket = require("lapis.config").get!.storage_bucket
          storage\delete_file bucket_key, @bucket_key!

  increment: =>
    import DailyUploadDownloads from require "models"
    DailyUploadDownloads\increment @id
    @update downloads_count: db.raw "downloads_count + 1"

  increment_audio: =>
    import DailyAudioPlays from require "models"
    DailyAudioPlays\increment @id
