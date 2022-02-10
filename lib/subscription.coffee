if Meteor.isClient
    Router.route '/subscriptions', (->
        @layout 'layout'
        @render 'subscriptions'
        ), name:'subscriptions'
    Router.route '/subscription/:doc_id/edit', (->
        @layout 'layout'
        @render 'subscription_edit'
        ), name:'subscription_edit'
    Router.route '/subscription/:doc_id', (->
        @layout 'layout'
        @render 'subscription_view'
        ), name:'subscription_view'
    Router.route '/subscription/:doc_id/view', (->
        @layout 'layout'
        @render 'subscription_view'
        ), name:'subscription_view_long'
    
    
    Template.subscriptions.onCreated ->
        @autorun => @subscribe 'subscription_docs',
            picked_tags.array()
            Session.get('subscription_title_filter')

        @autorun => @subscribe 'subscription_facets',
            picked_tags.array()
            Session.get('subscription_title_filter')

    
    
    Template.subscriptions.events
        'click .add_subscription': ->
            new_id = 
                Docs.insert 
                    model:'subscription'
            Router.go "/subscription/#{new_id}/edit"
            
            
            
    Template.subscriptions.helpers
        picked_tags: -> picked_tags.array()
    
        subscription_docs: ->
            Docs.find {
                model:'subscription'
                private:$ne:true
            }, sort:_timestamp:-1    
        tag_results: ->
            Results.find {
                model:'tag'
            }, sort:_timestamp:-1

    Template.user_subscriptions.onCreated ->
        @autorun => Meteor.subscribe 'user_subscriptions', Router.current().params.username, ->
    Template.user_subscriptions.helpers
        subscription_docs: ->
            Docs.find {
                model:'subscription'
            }, sort:_timestamp:-1    
    
    Template.subscription_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.subscription_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.subscription_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.subscription_card.events
        'click .view_subscription': ->
            Router.go "/subscription/#{@_id}"
    Template.subscription_item.events
        'click .view_subscription': ->
            Router.go "/subscription/#{@_id}"

    Template.subscription_view.events
        'click .add_subscription_recipe': ->
            new_id = 
                Docs.insert 
                    model:'recipe'
                    subscription_ids:[@_id]
            Router.go "/recipe/#{new_id}/edit"

    # Template.favorite_icon_toggle.helpers
    #     icon_class: ->
    #         if @favorite_ids and Meteor.userId() in @favorite_ids
    #             'red'
    #         else
    #             'outline'
    # Template.favorite_icon_toggle.events
    #     'click .toggle_fav': ->
    #         if @favorite_ids and Meteor.userId() in @favorite_ids
    #             Docs.update @_id, 
    #                 $pull:favorite_ids:Meteor.userId()
    #         else
    #             $('body').toast(
    #                 showIcon: 'heart'
    #                 message: "marked favorite"
    #                 showProgress: 'bottom'
    #                 class: 'success'
    #                 # displayTime: 'auto',
    #                 position: "bottom right"
    #             )

    #             Docs.update @_id, 
    #                 $addToSet:favorite_ids:Meteor.userId()
    
    
    Template.subscription_edit.events
        'click .delete_subscription': ->
            Swal.fire({
                title: "delete subscription?"
                text: "cannot be undone"
                icon: 'question'
                confirmButtonText: 'delete'
                confirmButtonColor: 'red'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'subscription removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/subscriptions"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish subscription?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_subscription', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'subscription published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish subscription?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_subscription', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'subscription unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'user_subscriptions', (username)->
        user = Meteor.users.findOne username:username
        
        Docs.find 
            model:'subscription'
            _author_id:user._id
    
    Meteor.publish 'subscription_count', (
        picked_tags
        picked_sections
        subscription_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_tags
        self = @
        match = {model:'subscription'}
        if picked_tags.length > 0
            match.ingredients = $all: picked_tags
            # sort = 'price_per_serving'
        if picked_sections.length > 0
            match.menu_section = $all: picked_sections
            # sort = 'price_per_serving'
        # else
            # match.tags = $nin: ['wikipedia']
        sort = '_timestamp'
            # match.source = $ne:'wikipedia'
        if view_vegan
            match.vegan = true
        if view_gf
            match.gluten_free = true
        if subscription_query and subscription_query.length > 1
            console.log 'searching subscription_query', subscription_query
            match.title = {$regex:"#{subscription_query}", $options: 'i'}
        Counts.publish this, 'subscription_counter', Docs.find(match)
        return undefined


if Meteor.isClient
    Template.subscription_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'
    Template.subscription_card.events
        'click .quickbuy': ->
            console.log @
            Session.set('quickbuying_id', @_id)
            # $('.ui.dimmable')
            #     .dimmer('show')
            # $('.special.cards .image').dimmer({
            #   on: 'hover'
            # });
            # $('.card')
            #   .dimmer('toggle')
            $('.ui.modal')
              .modal('show')

        'click .goto_food': (e,t)->
            # $(e.currentTarget).closest('.card').transition('zoom',420)
            # $('.global_container').transition('scale', 500)
            Router.go("/food/#{@_id}")
            # Meteor.setTimeout =>
            # , 100

        # 'click .view_card': ->
        #     $('.container_')

    Template.subscription_card.helpers
        subscription_card_class: ->
            # if Session.get('quickbuying_id')
            #     if Session.equals('quickbuying_id', @_id)
            #         'raised'
            #     else
            #         'active medium dimmer'
        is_quickbuying: ->
            Session.equals('quickbuying_id', @_id)

        food: ->
            # console.log Meteor.user().roles
            Docs.find {
                model:'food'
            }, sort:title:1
            