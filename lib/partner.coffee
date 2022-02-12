if Meteor.isClient
    Router.route '/partners', (->
        @layout 'layout'
        @render 'partners'
        ), name:'partners'
    Router.route '/partner/:doc_id/edit', (->
        @layout 'layout'
        @render 'partner_edit'
        ), name:'partner_edit'
    Router.route '/partner/:doc_id', (->
        @layout 'layout'
        @render 'partner_view'
        ), name:'partner_view'
    Router.route '/partner/:doc_id/view', (->
        @layout 'layout'
        @render 'partner_view'
        ), name:'partner_view_long'
    
    
    Template.partners.onCreated ->
        @autorun => @subscribe 'partner_docs',
            picked_tags.array()
            Session.get('partner_title_filter')

        @autorun => @subscribe 'partner_facets',
            picked_tags.array()
            Session.get('partner_title_filter')

    
    
    Template.partners.events
        'click .add_partner': ->
            new_id = 
                Docs.insert 
                    model:'partner'
            Router.go "/partner/#{new_id}/edit"
            
            
            
    Template.partners.helpers
        picked_tags: -> picked_tags.array()
    
        partner_docs: ->
            Docs.find {
                model:'partner'
                private:$ne:true
            }, sort:_timestamp:-1    
        tag_results: ->
            Results.find {
                model:'tag'
            }, sort:_timestamp:-1

    Template.user_partners.onCreated ->
        @autorun => Meteor.subscribe 'user_partners', Router.current().params.username, ->
    Template.user_partners.helpers
        partner_docs: ->
            Docs.find {
                model:'partner'
            }, sort:_timestamp:-1    
    
    Template.partner_view.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.partner_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.partner_card.onCreated ->
        @autorun => Meteor.subscribe 'doc_comments', @data._id, ->


    Template.partner_card.events
        'click .view_partner': ->
            Router.go "/partner/#{@_id}"
    Template.partner_item.events
        'click .view_partner': ->
            Router.go "/partner/#{@_id}"

    Template.partner_view.events
        'click .add_partner_recipe': ->
            new_id = 
                Docs.insert 
                    model:'recipe'
                    partner_ids:[@_id]
            Router.go "/recipe/#{new_id}/edit"

    
    Template.partner_edit.events
        'click .delete_partner': ->
            Swal.fire({
                title: "delete partner?"
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
                        title: 'partner removed',
                        showConfirmButton: false,
                        timer: 1500
                    )
                    Router.go "/partners"
            )

        'click .publish': ->
            Swal.fire({
                title: "publish partner?"
                text: "point bounty will be held from your account"
                icon: 'question'
                confirmButtonText: 'publish'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'publish_partner', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'partner published',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )

        'click .unpublish': ->
            Swal.fire({
                title: "unpublish partner?"
                text: "point bounty will be returned to your account"
                icon: 'question'
                confirmButtonText: 'unpublish'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Meteor.call 'unpublish_partner', @_id, =>
                        Swal.fire(
                            position: 'bottom-end',
                            icon: 'success',
                            title: 'partner unpublished',
                            showConfirmButton: false,
                            timer: 1000
                        )
            )
            
if Meteor.isServer
    Meteor.publish 'user_partners', (username)->
        user = Meteor.users.findOne username:username
        
        Docs.find 
            model:'partner'
            _author_id:user._id
    
    Meteor.publish 'partner_count', (
        picked_tags
        picked_sections
        partner_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_tags
        self = @
        match = {model:'partner'}
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
        if partner_query and partner_query.length > 1
            console.log 'searching partner_query', partner_query
            match.title = {$regex:"#{partner_query}", $options: 'i'}
        Counts.publish this, 'partner_counter', Docs.find(match)
        return undefined


if Meteor.isClient
    Template.partner_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'
    Template.partner_card.events
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

    Template.partner_card.helpers
        partner_card_class: ->
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
    Meteor.publish 'partner_facets', (
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
        match.model = 'partner'
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
        
    Meteor.publish 'partner_docs', (
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
        match.model = 'partner'
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