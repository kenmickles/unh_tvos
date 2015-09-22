Presenter =
  
  # something was clicked
  load: (e) ->
    el = e.target
    videoURL = el.getAttribute("videoURL")
    videoID = el.getAttribute("videoID")
    
    # we can't do much without a video
    return unless videoURL?

    player = new Player()
    playlist = new Playlist()
    mediaItem = new MediaItem('video', videoURL)

    # try to pull a resume time for this video from localStorage
    resumeTime = localStorage.getItem("resumeTime_#{videoID}")

    # if resume time is greater than 3, we assume it wasn't an accident
    if resumeTime && resumeTime > 3
      mediaItem.resumeTime = resumeTime
      
    # play video
    player.playlist = playlist
    player.playlist.push(mediaItem)
    player.present()

    # log video play time to localStorage, so we can resume later
    timeDidChange = (e) ->
      localStorage.setItem("resumeTime_#{videoID}", e.time)

    player.addEventListener('timeDidChange', timeDidChange, interval: 1)
  

  # turn a template string into a document
  makeDocument: (resource) ->
    Presenter.parser ?= new DOMParser()
    Presenter.parser.parseFromString(resource, "application/xml")
