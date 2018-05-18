prayerlib = require './node_modules/prayer/index.js'

calcMethod 	= 'Karachi' # Options: MWL|ISNA|Egypt|Makkah|Karachi|Tehran|Jafari
asrMethod  	= 'Hanafi'  # Options: Standard|Hanafi
hourFormat  = '12h'     # Options: 12h|24h 
addEdgeFiller = true    # Adds extra padding in case of first or last prayer, to keep ribbon-style identical

timelist = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']

command: ""

lat = 0
lon = 0

refreshFrequency: '1s'


render: -> """
	<div id="widget-title">Prayer Times : Loading...</div>
	<table>
		<thead><tr class="titles"></tr></thead>
		<tbody><tr class="values"></tr></tbody>
	</table>
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
	
	waqt = ''
	waqtIndex = -1
	
	for prayerName, i in timelist
		time = times[prayerName]
		if time <= curTime
			waqt = prayerName
			waqtIndex = i

	prevWaqt = ''
	nextWaqt = ''
	
	prevWaqt = timelist[waqtIndex-1] if waqtIndex > 0
	nextWaqt = timelist[waqtIndex+1] if waqtIndex < (timelist.length-1)

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
	base-color = #16AB83

	top: 100px
	left: 25px
	width: 350px
	background: rgba(#FFF, .3)
	padding: 5px 1px 6px 1px
	border-radius: 8px
	font-family: Helvetica Neue
	font-size: 12px
	
	#widget-title
		color: rgba(#37474F, 0.8)
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
		color: base-color
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
