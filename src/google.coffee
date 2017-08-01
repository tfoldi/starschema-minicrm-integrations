google = require('googleapis')
key = require('./servicekey.json')
fp = require('lodash/fp')


jwtClient = new (google.auth.JWT)(key.client_email, null, key.private_key, 'https://www.googleapis.com/auth/tasks', 'tfoldi@starschema.net')

jwtClient.authorize (err, tokens) ->
  console.log err if err
  
service = google.tasks('v1')
google.options {auth: jwtClient}

withFirstTasklist = (callback) ->
  service.tasklists.list {}, (err, response) ->
    return console.log 'The API returned an error: ' + err if err
    callback(err, fp.first response.items )


createTask = (tasklist,task,callback) ->
  console.log "create task => #{task.title}"
  service.tasks.insert {tasklist: tasklist, resource: task}, (err, response) ->
    callback( [err, response] )

googleTaskFromMiniCrmTodo = (project, todo) ->
  {
    title: "#{todo.Comment} - #{project.Name}"
    status: if todo.Status == "Open" then "needsAction" else "completed"
    notes: todo.Url
  }

googleTaskClose = (tasklist, task, callback) ->
  service.tasks.patch {tasklist: tasklist, task: task, resource: {status: 'completed' }}, (err, response) ->
    callback( [err, response] )

openOnly = fp.filter {Status: 'Open'}

forUser = (user) -> fp.filter ['UserId', user]

untilTomorrow = fp.filter (todo) -> Date.parse(todo.Deadline) < (Date.now() + 60 * 60 * 24 * 1000)

# relevant:
filterRelevantTodos = (todo,user,gtodos) ->
  fp.flow([
    #openOnly,
    untilTomorrow,
    forUser(user)
  ])(todo)

exports.syncGoogleTasks = (req, res) ->
  withFirstTasklist (err,tasklist) ->
    service.tasks.list {tasklist: tasklist.id}, (err, res) ->
      exports.getAllCrmTodo "45477", (project,todos) ->
        filterRelevantTodos(todos,45477).forEach (todo) ->
          gtodo = fp.find {notes: todo.Url}, res.items
          console.log project, todo, gtodo
          if gtodo == undefined and todo.Status == 'Open'
            createTask tasklist.id, googleTaskFromMiniCrmTodo(project,todo), (resp) ->
              console.log "Added google task", resp
          else if gtodo?.status == 'completed' and todo.Status == 'Open'
            # Close in MiniCRM
            exports.makeTodoComplete todo.Id
          else if todo.Status == 'Closed' and gtodo?.status == 'needsAction'
            googleTaskClose tasklist.id, gtodo.id, (resp) ->
              console.log resp
    service.tasks.clear {tasklist: tasklist.id}, (err, res) ->
      console.log "Tasklist #{tasklist.name} has been cleared"
  res?.status(200).end()
