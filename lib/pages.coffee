if Meteor.isClient
    Router.route '/catering', (->
        @render 'catering'
        ), name:'catering'