require('./assets/lib/piety')($, document)

## CPU Usage Widget
## Based on https://github.com/Amar1729/nerdbar.widget/blob/master/cpu.coffee

## Colors Used by the chart
colors =
  low: 'rgb(255,44,37)'
  med: 'orange'
  high: 'rgb(133, 188, 86)'
  back: 'rgba(0,0,0,0.3)'

##  Width of the chart
chartWidth = 20
segments = 10
chartType = 'bar'

refreshFrequency: 2000 # ms

values   = (1 for i in [0...segments]).join(",")

command: "pmset -g batt | grep -o '[0-9]*%; [a-z]*'"

render: (output) ->
  """
  <div class="battery">
    <span class='status'></span>
    <span class="chart">#{values}</span>
    <span class='number'></span>
  </div>
  """

update: (output, el) ->
  values = output.split("%;")
  
  percent = values[0]
  battery = Number(percent)
  
  status = values[1].replace /^\s+|\s+$/g, ""
  statusIcon = if status == 'charging' then '⚡️' else ''

  fill = colors.low
  ## Medium Threshold
  if battery >= 20
    fill = colors.med
  ## High Threshold
  if battery > 60
    fill = colors.high

  ## Set Text
  $(".battery .number", el).text("  #{battery}%")
  $(".battery .status", el).text("  #{statusIcon}")

  ## Set Chart Data
  batteryValue = Math.round(segments*battery/100)
  fillColors = ((if batteryValue > x  then fill else colors.black) for x in [0..segments])

  $(".battery .chart", el).peity chartType,
    fill: fillColors
    width: chartWidth
    height: 10


style: """
  left: 210px
  bottom: 3px

  color: white
  font: 12px Inconsolata, monospace, Helvetica Neue, sans-serif
  -webkit-font-smoothing: antialiased

  .number
    display inline-block
    vertical-align top
    margin -1px 0 0 0

  .chart
    vertical-align top

  .status
    font-size: 8px
    float: left
"""
