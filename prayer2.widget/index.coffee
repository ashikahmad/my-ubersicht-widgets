prayerlib = require './node_modules/prayer/index.js'

calcMethod 	= 'Karachi' # Options: MWL|ISNA|Egypt|Makkah|Karachi|Tehran|Jafari
asrMethod  	= 'Hanafi'  # Options: Standard|Hanafi
hourFormat  = '12h'     # Options: 12h|24h 
addEdgeFiller = true    # Adds extra padding in case of first or last prayer, to keep ribbon-style identical

timelist = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']

command: ""

lat = 0
lon = 0
showFullView = false

refreshFrequency: '1s'
icon = '🕌'


render: -> """
	<div id="fullview">
		<div id="widget-title">Prayer Times : Loading...</div>
		<table>
			<thead><tr class="titles"></tr></thead>
			<tbody><tr class="values"></tr></tbody>
		</table>
	</div>
	<div id="smallview">
		<span id="smallicon">#{icon}</span>
		<span id="smalltitle"> ... </span>
		<span id="smallvalue">
		</span></div>
	"""


afterRender: (domEl) ->
	prayerlib.setMethod calcMethod
	prayerlib.adjust {asr: asrMethod}

	geolocation.getCurrentPosition (geo) =>
		coords = geo.position.coords
		lat = coords.latitude
		lon = coords.longitude
		
		cityName = geo.address.state
		$(domEl).find('#widget-title').text "Prayer Times : #{cityName}"
		
		@refresh()


update: (output, domEl) ->
	return "" if lat == 0

	dt = new Date
	curTime = dt.getHours() + dt.getMinutes() / 60
	times = prayerlib.getTimes dt, [lat, lon], 'auto', 'auto', 'Float' 
	
	[waqtIndex, waqt, prevWaqt, nextWaqt] = @findWaqt times, curTime
	
	if showFullView == true
		@renderFullView times, domEl, waqtIndex, waqt, prevWaqt, nextWaqt

	@renderSmallView times, domEl, waqtIndex, waqt, prevWaqt, nextWaqt, curTime


findWaqt: (times, curTime) ->
	waqt = ''
	waqtIndex = -1
	
	for prayerName, i in timelist
		time = times[prayerName]
		if time <= curTime
			waqt = prayerName
			waqtIndex = i

	prevWaqt = if waqtIndex > 0 then timelist[waqtIndex-1] else ''
	nextWaqt = if waqtIndex < (timelist.length-1) then timelist[waqtIndex+1] else ''
	[waqtIndex, waqt, prevWaqt, nextWaqt]


renderFullView: (times, domEl, waqtIndex, waqt, prevWaqt, nextWaqt) ->
	titles = ''
	values = ''

	for prayerName in timelist
		time = times[prayerName]
		formatted = prayerlib.getFormattedTime time, hourFormat, []

		className = "normal"
		if prayerName == waqt then className = "current"
		else if prayerName == prevWaqt then className = "passed"
		else if prayerName == nextWaqt then className = "upcoming"

		titles += "<td class='#{className}'>#{prayerName}</td>"
		values += "<td class='#{className}'>#{formatted}</td>"

	titles = @fillSides titles, waqtIndex, timelist.length
	values = @fillSides values, waqtIndex, timelist.length

	$(domEl).find('.titles').html titles
	$(domEl).find('.values').html values


renderSmallView: (times, domEl, waqtIndex, waqt, prevWaqt, nextWaqt, curTime) ->
	waqt = timelist[timelist.length-1] if waqtIndex == -1
	nextWaqt = timelist[0] if waqtIndex == timelist.length-1

	remaining = times[nextWaqt] - curTime
	remaining += 24 if remaining < 0
	remaining = prayerlib.getFormattedTime remaining, '24h', []	
	
	$(domEl).find('#smallicon').text "#{icon}"
	$(domEl).find('#smalltitle').text " #{waqt}"
	$(domEl).find('#smallvalue').text " -#{remaining}"
	
	showFull = ->
		showFullView = true
		$(domEl).find('#fullview').fadeIn(150)
		@refresh
	hideFull = ->
		showFullView = false
		$(domEl).find('#fullview').fadeOut(150)
	$(domEl).find('#smallview').hover showFull, hideFull


fillSides: (cols, index, total) ->
	fixedCols = cols

	if addEdgeFiller
		if index==0
			fixedCols = "<td class='passed filler'></td>#{cols}"
		else if index==total-1
			fixedCols = "#{cols}<td class='upcoming filler'></td>"
	
	return fixedCols


style: """
	current-round = 6px
	no-bg = rgba(#000, .0)
	base-color = rgba(#00897B, 0.8)

	bottom: 3px
	left: 500px
	-webkit-font-smoothing: antialiased

	#fullview
		width: 350px
		background: rgba(#000, 0.4)
		padding: 5px 1px 6px 1px
		border-radius: 8px
		font-family: Helvetica Neue
		font-size: 12px
		margin: 0 0 7px -60px
		display: none

	#smallview
		display: inline-block
		background #0006
		color: rgba(#fff, 0.9)
		padding: 1px 5px
		border-radius: 2px
		font: 13px Inconsolata, monospace, Helvetica Neue, sans-serif

	#smallicon
		font-size: 11px

	#smalltitle
		text-transform: capitalize

	#widget-title
		color: rgba(#FFF, 0.7)
		font-size: 14px
		font-weight: 500
		padding: 0 0 5px 5px

	table
		font-weight: 400
		width: 100%
		text-align:center
		border-collapse:collapse

	td
		color: rgba(#fff, 0.8)
		padding: 0 5px 0 5px
		background: base-color

	.titles
		font-size: 10px
		text-transform: uppercase
		font-weight: bold

	.values
		font-size: 14px
		font-weight: 300
		color: rgba(#fff, .9)

	.current
		color: rgba(#FFE57F, 0.8)
		background: no-bg
		font-weight: 800

	.titles .current
		font-size: 12px

	.titles .passed
		border-top-right-radius: current-round

	.values .passed
		border-bottom-right-radius: current-round

	.titles .upcoming
		border-top-left-radius: current-round

	.values .upcoming
		border-bottom-left-radius: current-round

	.filler
		padding: 0 2px 0 2px
	"""
