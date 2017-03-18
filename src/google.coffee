google = require('googleapis')
key = require('./servicekey.json')
fp = require('lodash/fp')


jwtClient = new (google.auth.JWT)(key.client_email, null, key.private_key, 'https://www.googleapis.com/auth/tasks', 'tfoldi@starschema.net')

jwtClient.authorize (err, tokens) ->
  if err
    console.log err
  
service = google.tasks('v1')
google.options {auth: jwtClient}

withFirstTasklist = (callback) ->
  service.tasklists.list {}, (err, response) ->
    if err
      console.log 'The API returned an error: ' + err
      return
    callback(err, fp.first response.items )


createTask = (tasklist,task,callback) ->
#  return console.log "create task => #{task.title}"
  service.tasks.insert {tasklist: tasklist, resource: task}, (err, response) ->
    callback( [err, response] )

googleTaskFromMiniCrmTodo = (project, todo) ->
  {
    title: "#{todo.Comment} - #{project.Name}"
    status: if todo.Status == "Open" then "needsAction" else "completed"
    notes: todo.Url
  }

openOnly = fp.filter {Status: 'Open'}

forUser = (user) -> fp.filter ['UserId', user]

filterRelevantTodos = (todo,user) ->
  fp.flow([
    openOnly,
    forUser(user)
  ])(todo)

exports.syncGoogleTasks = (req, res) ->
  withFirstTasklist (err,tasklist) ->
    console.log(tasklist)
    service.tasks.list {tasklist: tasklist.id}, (err, res) ->
      console.log "Items:" , res.items
      exports.getAllCrmTodo "45477", (project,todos) ->
        for todo in filterRelevantTodos(todos,45477)
          console.log project, todo
          createTask tasklist.id, googleTaskFromMiniCrmTodo(project,todo), (resp) ->
            console.log resp

  res?.status(200).end()
