if Meteor.isClient
    Router.route '/catering', (->
        @render 'catering'
        ), name:'catering'
        
    Router.route '/mission', (->
        @render 'mission'
        ), name:'mission'
        
        
        