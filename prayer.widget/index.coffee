# See bottom of the file for command parameter details.

calcMethod 	= 1
asrMethod  	= 1

hourFormat12  : true # If false, times shows in 24Hour format, otherwise in 12Hour format (without AM/PM)
hideSunset 	  : true # As Mugrib and Sunset times are same, It is preffered to hide Sunset column
addEdgeFiller : true # Adds extra padding in case of Fazr and Isha, to keep ribbon-style identical

command: ""

refreshFrequency: 15000


render: -> """
	<div id="widget-title">Prayer Times : Loading...</div>
	<table>
		<thead><tr class="titles"></tr></thead>
		<tbody><tr class="values"></tr></tbody>
	</table>
	"""


afterRender: (domEl) ->
	geolocation.getCurrentPosition (geo) =>
		coords = geo.position.coords
		lat = coords.latitude
		lon = coords.longitude
		
		dt = new Date
		tz = dt.getTimezoneOffset() * -1 / 60 
		
		cityName = geo.address.state
		
		@command = "php -f ./prayer.widget/lib/PrayTime.php calc_method=#{calcMethod} asr_method=#{asrMethod} lat=#{lat} lon=#{lon} tz=#{tz}"
		$(domEl).find('#widget-title').text "Prayer Times : #{cityName}"
		
		@refresh()


update: (output, domEl) ->
	titles = ""
	values = ""

	lines = output.split "\n"
	return "" if lines.length < 2

	names = lines[0].split ","
	times = lines[1].split ","

	if this.hideSunset
		names.splice(4,1)
		times.splice(4,1)

	curIndex = times.length-1
	now = new Date()
	time = new Date()
	for timeI, i in times
		timeComp = timeI.split ":"
		time.setHours(timeComp[0], timeComp[1])
		if time.getTime() < now.getTime() then curIndex = i else break
	
	for hhmm, i in times
			className = "normal";
			if i == curIndex then className = "current"
			else if i == curIndex-1 then className = "passed"
			else if i == curIndex+1 then className = "upcoming"
			if this.hourFormat12
				hhmm = hhmm.split ":"
				hhmm[0] -= if hhmm[0]>12 then 12 else 0
				hhmm = hhmm.join ":"

			titles += "<td class='#{className}'>#{names[i]}</td>"
			values += "<td class='#{className}'>#{hhmm}</td>"

	$(domEl).find('.titles').html(this.fillSides(titles, curIndex, names.length))
	$(domEl).find('.values').html(this.fillSides(values, curIndex, times.length))


fillSides: (cols, current, total) -> 
	if this.addEdgeFiller
		if current==0
			return "<td class='passed filler'></td>#{cols}"
		else if current==total-1
			return "#{cols}<td class='upcoming filler'></td>"

	return cols


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

###
COMMAND PARAMETER DETAILS 
---------------------------

1. calcMethod : Calculation method
=> Possible values:
	0: Ithna Ashari
  1: University of Islamic Sciences, Karachi
  2: Islamic Society of North America (ISNA)
  3: Muslim World League (MWL)
  4: Umm al-Qura, Makkah
  5: Egyptian General Authority of Survey
  6: Custom Setting
  7: Institute of Geophysics, University of Tehran

2. asrMethod : Juristic Methods / Asr Calculation Methods
=> Possible values:
  0: Shafii (standard)
  1: Hanafi
###
