if Meteor.isClient
    Router.route '/catering', (->
        @layout 'layout'
        @render 'catering'
        ), name:'catering'
    Router.route '/catering_orders', (->
        @layout 'layout'
        @render 'catering_orders'
        ), name:'catering_orders'
    Router.route '/catering_order/:doc_id/edit', (->
        @layout 'layout'
        @render 'catering_order_edit'
        ), name:'catering_order_edit'
    Router.route '/catering_order/:doc_id', (->
        @layout 'layout'
        @render 'catering_order_view'
        ), name:'catering_order_view'
    Router.route '/catering_order/:doc_id/view', (->
        @layout 'layout'
        @render 'catering_order_view'
        ), name:'catering_order_view_long'
    
    
    Template.catering_orders.onCreated ->
        @autorun => @subscribe 'catering_order_docs',
            picked_tags.array()
            Session.get('catering_order_title_filter')

        @autorun => @subscribe 'catering_order_facets',
            picked_tags.array()
            Session.get('catering_order_title_filter')

    
    
    Template.catering_orders.events
        'click .add_catering_order': ->
            new_id = 
                Docs.insert 
                    model:'catering_order'
            Router.go "/catering_order/#{new_id}/edit"
            
            
            
    Template.catering_orders.helpers
        picked_tags: -> picked_tags.array()
    
        catering_order_docs: ->
            Docs.find {
                model:'catering_order'
                private:$ne:true
            }, sort:_timestamp:-1    
        tag_results: ->
            Results.find {
                model:'tag'
            }, sort:_timestamp:-1

    Template.user_catering_orders.onCreated ->
        @autorun => Meteor.subscribe 'user_catering_orders', Router.current().params.username, ->
    Template.user_catering_orders.helpers
        catering_order_docs: ->
            Docs.find {
                model:'catering_order'
            }, sort:_timestamp:-1    
    
    Template.catering_order_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.catering_order_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.catering_order_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.catering_order_card.events
        'click .view_catering_order': ->
            Router.go "/catering_order/#{@_id}"

    Template.catering_order_view.events
        'click .add_catering_order_recipe': ->
            new_id = 
                Docs.insert 
                    model:'recipe'
                    catering_order_ids:[@_id]
            Router.go "/recipe/#{new_id}/edit"

    
    Template.catering_order_edit.events
        'click .delete_catering_order': ->
            Swal.fire({
                title: "delete catering_order?"
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
                        title: 'catering_order removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/catering_orders"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish catering_order?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_catering_order', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'catering_order published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish catering_order?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_catering_order', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'catering_order unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'user_catering_orders', (username)->
        user = Meteor.users.findOne username:username
        
        Docs.find 
            model:'catering_order'
            _author_id:user._id
    
    Meteor.publish 'catering_order_count', (
        picked_tags
        picked_sections
        catering_order_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_tags
        self = @
        match = {model:'catering_order'}
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
        if catering_order_query and catering_order_query.length > 1
            console.log 'searching catering_order_query', catering_order_query
            match.title = {$regex:"#{catering_order_query}", $options: 'i'}
        Counts.publish this, 'catering_order_counter', Docs.find(match)
        return undefined


if Meteor.isClient
    Template.catering_order_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'
    Template.catering_order_card.events
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

    Template.catering_order_card.helpers
        catering_order_card_class: ->
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
            
            
            
if Meteor.isServer
    Meteor.publish 'catering_order_facets', (
        picked_tags=[]
        title_filter
        picked_authors=[]
        picked_tasks=[]
        picked_locations=[]
        picked_timestamp_tags=[]
        )->
        # console.log 'dummy', dummy
        # console.log 'query', query
        # console.log 'picked staff', picked_authors
    
        self = @
        match = {}
        # match = {app:'pes'}
        match.model = 'catering_order'
        # match.group_id = Meteor.user().current_group_id
        
        if title_filter and title_filter.length > 1
            match.title = {$regex:title_filter, $options:'i'}
        
        # if view_vegan
        #     match.vegan = true
        # if view_gf
        #     match.gluten_free = true
        # if view_local
        #     match.local = true
        if picked_authors.length > 0 then match._author_username = $in:picked_authors
        if picked_tags.length > 0 then match.tags = $all:picked_tags 
        if picked_locations.length > 0 then match.location_title = $in:picked_locations 
        if picked_timestamp_tags.length > 0 then match._timestamp_tags = $in:picked_timestamp_tags 
        # match.$regex:"#{product_query}", $options: 'i'}
        # if product_query and product_query.length > 1
        author_cloud = Docs.aggregate [
            { $match: match }
            { $project: "_author_username": 1 }
            { $group: _id: "$_author_username", count: $sum: 1 }
            { $match: _id: $nin: picked_authors }
            # { $match: _id: {$regex:"#{product_query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 10 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
        
        author_cloud.forEach (author, i) =>
            # console.log 'queried author ', author
            # console.log 'key', key
            self.added 'results', Random.id(),
                title: author.title
                count: author.count
                model:'author'
                # category:key
                # index: i
    
        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            # { $match: _id: {$regex:"#{product_query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 20 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
        
        tag_cloud.forEach (tag, i) =>
            # console.log 'queried tag ', tag
            # console.log 'key', key
            self.added 'results', Random.id(),
                title: tag.title
                count: tag.count
                model:'tag'
                # category:key
                # index: i
    
    
        location_cloud = Docs.aggregate [
            { $match: match }
            { $project: "location_title": 1 }
            # { $unwind: "$locations" }
            { $match: _id: $nin: picked_locations }
            { $group: _id: "$location_title", count: $sum: 1 }
            { $sort: count: -1, _id: 1 }
            { $limit: 10 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
    
        location_cloud.forEach (location, i) =>
            # console.log 'location result ', location
            self.added 'results', Random.id(),
                title: location.title
                count: location.count
                model:'location'
                # category:key
                # index: i
    
        timestamp_tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "_timestamp_tags": 1 }
            { $unwind: "$_timestamp_tags" }
            { $match: _id: $nin: picked_timestamp_tags }
            { $group: _id: "$_timestamp_tags", count: $sum: 1 }
            { $sort: count: -1, _id: 1 }
            { $limit: 10 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
    
        timestamp_tag_cloud.forEach (timestamp_tag, i) =>
            # console.log 'timestamp_tag result ', timestamp_tag
            self.added 'results', Random.id(),
                title: timestamp_tag.title
                count: timestamp_tag.count
                model:'timestamp_tag'
                # category:key
                # index: i
    
    
    
    
        self.ready()
        
    Meteor.publish 'catering_order_docs', (
        picked_tags
        # title_filter
        # picked_authors=[]
        # picked_tasks=[]
        # picked_locations=[]
        # picked_timestamp_tags=[]
        # product_query
        # view_vegan
        # view_gf
        # doc_limit
        # doc_sort_key
        # doc_sort_direction
        )->
    
        self = @
        match = {}
        # match = {app:'pes'}
        match.model = 'catering_order'
        # match.group_id = Meteor.user().current_group_id
        # if title_filter and title_filter.length > 1
        #     match.title = {$regex:title_filter, $options:'i'}
        
        # if view_vegan
        #     match.vegan = true
        # if view_gf
        #     match.gluten_free = true
        # if view_local
        #     match.local = true
        # if picked_authors.length > 0 then match._author_username = $in:picked_authors
        # if picked_tags.length > 0 then match.tags = $all:picked_tags 
        # if picked_locations.length > 0 then match.location_title = $in:picked_locations 
        # if picked_timestamp_tags.length > 0 then match._timestamp_tags = $in:picked_timestamp_tags 
        console.log match
        Docs.find match, 
            limit:20
            sort:
                _timestamp:-1