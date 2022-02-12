if Meteor.isClient
    Router.route '/prepared', (->
        @layout 'layout'
        @render 'prepared'
        ), name:'prepared'
        
        
    Template.prepared.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'plan', ->

    Template.prepared.helpers
        plan_docs:->
            Docs.find 
                model:'plan'
    
    Template.prepared.events
        'click .add_plan': ->
            Docs.insert 
                model:'plan'
                
        'click .sign_up': ->
            new_id = 
                Docs.insert 
                    model:'subscription'
            Router.go "/subscription/#{new_id}/edit"
            