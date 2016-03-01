sprintf = require('sprintf-js').sprintf
assembly = require './assembly'
calculator = require './calculator'
copper = require './copper'
courtyard = require './courtyard'
silkscreen = require './silkscreen'

abbrs =
  CAP: 'capacitor'
  DIO: 'diode'
  IND: 'inductor'
  LED: 'led'
  RES: 'resistor'
  XTAL: 'crystal'

getAbbr = (element) ->
  abbr = 'U'
  unless element.keywords? then return name
  keywords = element.keywords.replace(/\s+/g, '').split(',')
  for k, v of abbrs
    if keywords.indexOf(v) isnt -1
      abbr = k
      break
  abbr

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  abbr = getAbbr element

  if housing.polarized and (abbr isnt 'DIO') and (abbr isnt 'LED') then abbr += 'P'

  if housing.cae
    abbr += 'AE'
    option = 'crystal' # CAE is the same as crystal
    size = sprintf "%dX%d",
      [housing.bodyWidth.nom*100
      height*100]
      .map((v) => Math.round v)...
  else if housing.concave
    abbr += 'SC'
    option = 'concave'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.crystal
    option = 'crystal'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.dfn
    abbr += 'DFN'
    option = 'dfn'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...
  else if housing.molded
    abbr += 'M'
    option = 'molded'
    size = sprintf "%02d%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...
  else if housing.melf
    abbr += 'MELF'
    option = 'melf'
    size = sprintf "%02d%02d",
      [housing.bodyLength.nom*10,
      housing.bodyDiameter.nom*10]
      .map((v) => Math.round v)...
  else if housing.sod
    abbr = 'SOD'
    option = 'sod'
    size = sprintf "%02d%02dX%d",
      [housing.leadSpan.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.sodfl
    abbr = 'SODFL'
    option = 'sodfl'
    size = sprintf "%02d%02dX%d",
      [housing.leadSpan.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else
    abbr += 'C'
    option = 'chip'
    size = sprintf "%02d%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.chip pattern, housing, option

  pattern.name ?= sprintf "%s%s%s",
    abbr,
    size,
    settings.densityLevel

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']
    x: -padParams.distance/2
    y: 0

  # Copper
  pattern.pad 1, pad
  pad.x = -pad.x
  pattern.pad 2, pad

  silkscreen.twopin pattern, housing
  assembly.twopin pattern, housing
  courtyard.twopin pattern, housing, padParams.courtyard
