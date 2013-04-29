request = require './request-as-promised'
cheerio = require 'cheerio'
Q = require 'q'

url = 'http://www.nitt.edu/prm/nitreg/ShowRes.aspx'

_defaultSemesters = [{
  code: 'latest'
  name: 'Most Recent Examination'
}]

getViewState = (body)->
  body.match(/name="__VIEWSTATE" value="(.+?)"/)[1]

hasResult = (body)->
  null isnt body.match /LblGPA/

doInitialRequest = (rollno)->
  (request {
    method: 'GET'
    uri: url
  })
  .then (response)->
    request {
      method: 'POST'
      uri: url
      form: {
        TextBox1: rollno
        Button1: 'Show'
        __VIEWSTATE: getViewState response.body
      }
      headers: {
        Referer: url
      }
    }

getResultCallback = (rollno, sem)->
  (arr)->
    resultOptions = arr[0]
    response = arr[1]
    if sem is 'latest'
      sem = resultOptions[resultOptions.length - 1].code
    (request {
      method: 'POST'
      uri: url
      form: {
        TextBox1: rollno
        Dt1: sem
        __VIEWSTATE: getViewState response.body
        __EVENTTARGET: 'Dt1'
        __EVENTARGUMENT: ''
      }
      headers: {
        Referer: url
      }
    })
    .then (response)->
      jsonizeResults response, sem, resultOptions

getResultPromise = (promise, rollno, sem)->
  promise.then getResultCallback(rollno, sem)

common = (rollno, sem)->
  options = false
  firstYearHack = false

  if sem is undefined
    options = true

  promise = (doInitialRequest rollno)
  .then (response)->
    resultOptions = _defaultSemesters
    optionsRegex = /\<option value="(.+?)"\>(.+?)\<\/option\>/g

    while match = optionsRegex.exec response.body
      if '0' isnt match[1]
        resultOptions.push {
          code: match[1]
          name: match[2]
        }
    if resultOptions.length is 0 and hasResult response.body
      firstYearHack = true
      sem = 'Unknown'
    [resultOptions, response]

  if firstYearHack is true or options is true
    return promise

  promise.then getResultCallback rollno, sem

jsonizeResults = (response, sem, otherSems)->
  $ = cheerio.load response.body, {ignoreWhitespace: true}

  ($ '#Dt1 option').each (i, elem)->
    if ($ this).attr('selected') isnt 'selected'
      return;
    sem = ($ this).attr('value')

  if sem is undefined
    sem = 'latest'

  data = {
    name: ($ '#LblName b font').text()
    rollno: ($ '#LblEnrollmentNo b font').text()
    credits: {
      total: ($ '#LblRegCr b font').text()
      earned: ($ '#LblErCr b font').text()
    }
    gpa: ($ '#LblGPA b font').text()
    exam: ($ '#LblExamName b font').text()
    semesterCode: sem
    semsters: otherSems
    courses: []
  }
  ($ '#DataGrid1 tr').each (i, elem)->
    if (($ this).attr 'class') is 'DataGridHeader'
      return
    fontTags = $ 'td font', $(this).toString()
    data.courses.push {
      code: ($ fontTags[1]).text()
      name: ($ fontTags[2]).text()
      credits: ($ fontTags[3]).text()
      grade: ($ fontTags[4]).text()
      attendence: ($ fontTags[5]).text()
    }
  data

module.exports = {
  getResult: (rollno, sem)->
    (common rollno, sem)
  getSems: (rollno)->
    (common rollno)
    .then (arr)->
      resultOptions = arr[0]
      response = arr[1]
      resultOptions
  getAllResults: (rollno)->
    promise = common rollno
    promiseList = []
    promise.then (arr)->
      resultOptions = arr[0]
      response = arr[1]
      for result in resultOptions
        if result.code is "latest"
          continue
        promiseList.push getResultPromise(promise, rollno, result.code)
      Q.all promiseList
  getLatestResult: (rollno)->
    module.exports.getResult(rollno, 'latest')
}
