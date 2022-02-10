if Meteor.isClient
    Router.route '/chef/:doc_id', (->
        @layout 'layout'
        @render 'chef_view'
        ), name:'chef_view'
        
    Router.route '/chef/:doc_id/view', (->
        @layout 'layout'
        @render 'chef_view'
        ), name:'chef_view_long'

        

    Template.chef_view.onCreated ->
        @autorun => Meteor.subscribe 'chef_source', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id, ->
    Template.chef_view.onRendered ->
        Meteor.call 'log_view', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'ingredients_from_chef_id', Router.current().params.doc_id
    Template.chef_view.events
        'click .goto_source': (e,t)->
            $(e.currentTarget).closest('.pushable').transition('fade right', 240)
            chef = Docs.findOne Router.current().params.doc_id
            Meteor.setTimeout =>
                Router.go "/source/#{chef.source_id}"
            , 240
        
        'click .goto_ingredient': (e,t)->
            # $(e.currentTarget).closest('.pushable').transition('fade right', 240)
            chef = Docs.findOne Router.current().params.doc_id
            console.log @
            found_ingredient = 
                Docs.findOne 
                    model:'ingredient'
                    title:@valueOf()
            if found_ingredient
                Router.go "/ingredient/#{found_ingredient._id}"
            else 
                new_id = 
                    Docs.insert 
                        model:'ingredient'
                        title:@valueOf()
                Router.go "/ingredient/#{new_id}/edit"
                
            # found_ingredient = 
            #     Docs.findOne 
            #         model:'ingredient'
            #         title:@valueOf()
            # Meteor.setTimeout =>
            #     Router.go "/source/#{chef.source_id}"
            # , 240
        


    Template.chef_view.helpers
        chef_order_total: ->
            orders = 
                Docs.find({
                    model:'order'
                    chef_id:@_id
                }).fetch()
            res = 0
            for order in orders
                res += order.order_price
            res
                
        chef_docs: ->
            Docs.find({
                model:'chef'
            })
                

        can_cancel: ->
            chef = Docs.findOne Router.current().params.doc_id
            if Meteor.userId() is chef._author_id
                if chef.ready
                    false
                else
                    true
            else if Meteor.userId() is @_author_id
                if chef.ready
                    false
                else
                    true



if Meteor.isServer
    Meteor.publish 'chef_sources', (chef_id)->
        chef = Docs.findOne chef_id
        # console.log 'need source from this chef', chef
        Docs.find
            model:'source'
            _id:chef.source_id
    Meteor.publish 'orders_from_chef_id', (chef_id)->
        # chef = Docs.findOne chef_id
        Docs.find
            model:'order'
            chef_id:chef_id
            
    Meteor.publish 'subs_from_chef_id', (chef_id)->
        # chef = Docs.findOne chef_id
        Docs.find
            model:'chef_subscription'
            chef_id:chef_id
    Meteor.publish 'inventory_from_chef_id', (chef_id)->
        # chef = Docs.findOne chef_id
        Docs.find
            model:'inventory_item'
            chef_id:chef_id





if Meteor.isClient
    Router.route '/chef/:doc_id/edit', (->
        @layout 'layout'
        @render 'chef_edit'
        ), name:'chef_edit'


    Template.chef_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'model_docs', 'source'

    Template.chef_edit.onRendered ->
        Meteor.setTimeout ->
            today = new Date()
            $('#availability')
                .calendar({
                    inline:true
                    # minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate() - 5),
                    # maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 5)
                })
        , 2000

    Template.chef_edit.helpers
        # all_shop: ->
        #     Docs.find
        #         model:'chef'
        can_delete: ->
            chef = Docs.findOne Router.current().params.doc_id
            if chef.reservation_ids
                if chef.reservation_ids.length > 1
                    false
                else
                    true
            else
                true

    Template.chef_edit.onCreated ->
        @autorun => @subscribe 'source_search_results', Session.get('source_search'), ->
    Template.chef_edit.helpers
        search_results: ->
            Docs.find 
                model:'source'
                

    Template.chef_edit.events
        'click .remove_source': (e,t)->
            if confirm 'remove source?'
                Docs.update Router.current().params.doc_id,
                    $set:source_id:null
        'click .pick_source': (e,t)->
            Docs.update Router.current().params.doc_id,
                $set:source_id:@_id
        'keyup .source_search': (e,t)->
            # if e.which is '13'
            val = t.$('.source_search').val()
            console.log val
            Session.set('source_search', val)
                
            
        'click .save_chef': ->
            chef_id = Router.current().params.doc_id
            Meteor.call 'calc_chef_data', chef_id, ->
            Router.go "/chef/#{chef_id}"


        'click .save_availability': ->
            doc_id = Router.current().params.doc_id
            availability = $('.ui.calendar').calendar('get date')[0]
            console.log availability
            formatted = moment(availability).format("YYYY-MM-DD[T]HH:mm")
            console.log formatted
            # console.log moment(@end_datetime).diff(moment(@start_datetime),'minutes',true)
            # console.log moment(@end_datetime).diff(moment(@start_datetime),'hours',true)
            Docs.update doc_id,
                $set:datetime_available:formatted





        # 'click .select_chef': ->
        #     Docs.update Router.current().params.doc_id,
        #         $set:
        #             chef_id: @_id
        #
        #
        # 'click .clear_chef': ->
        #     if confirm 'clear chef?'
        #         Docs.update Router.current().params.doc_id,
        #             $set:
        #                 chef_id: null



        'click .delete_chef': ->
            if confirm 'refund orders and cancel chef?'
                Docs.remove Router.current().params.doc_id
                Router.go "/"

if Meteor.isServer 
    Meteor.publish 'source_search_results', (source_title_queary)->
        Docs.find 
            model:'source'
            title: {$regex:"#{source_title_queary}",$options:'i'}


if Meteor.isClient
    Template.ingredient_picker.onCreated ->
        @autorun => @subscribe 'ingredient_search_results', Session.get('ingredient_search'), ->
        @autorun => @subscribe 'model_docs', 'ingredient', ->
    Template.ingredient_picker.helpers
        ingredient_results: ->
            Docs.find 
                model:'ingredient'
                title: {$regex:"#{Session.get('ingredient_search')}",$options:'i'}
                
        chef_ingredients: ->
            chef = Docs.findOne Router.current().params.doc_id
            Docs.find 
                # model:'ingredient'
                _id:$in:chef.ingredient_ids
        ingredient_search_value: ->
            Session.get('ingredient_search')
        
    Template.ingredient_picker.events
        'click .clear_search': (e,t)->
            Session.set('ingredient_search', null)
            t.$('.ingredient_search').val('')

            
        'click .remove_ingredient': (e,t)->
            if confirm "remove #{@title} ingredient?"
                Docs.update Router.current().params.doc_id,
                    $pull:
                        ingredient_ids:@_id
                        ingredient_titles:@title
        'click .pick_ingredient': (e,t)->
            Docs.update Router.current().params.doc_id,
                $addToSet:
                    ingredient_ids:@_id
                    ingredient_titles:@title
            Session.set('ingredient_search',null)
            t.$('.ingredient_search').val('')
                    
        'keyup .ingredient_search': (e,t)->
            # if e.which is '13'
            val = t.$('.ingredient_search').val()
            console.log val
            Session.set('ingredient_search', val)

        'click .create_ingredient': ->
            new_id = 
                Docs.insert 
                    model:'ingredient'
                    title:Session.get('ingredient_search')
            Router.go "/ingredient/#{new_id}/edit"


if Meteor.isServer 
    Meteor.publish 'ingredient_search_results', (ingredient_title_query)->
        Docs.find 
            model:'ingredient'
            title: {$regex:"#{ingredient_title_query}",$options:'i'}
    Meteor.publish 'chef_orders', (chef_id)->
        chef = Docs.findOne chef_id
        # console.log 'finding mishi for', chef
        if chef.slug 
            Docs.find 
                model:'order'
                _chef:chef.slug
        # else console.log 'no chef slug', chef
        
        
if Meteor.isClient
    Router.route '/chefs', (->
        @layout 'layout'
        @render 'chefs'
        ), name:'chefs'


    Template.chef_card.events
        'click .add_to_cart': (e,t)->
            $(e.currentTarget).closest('.card').transition('bounce',500)
            Meteor.call 'add_to_cart', @_id, =>
                $('body').toast(
                    showIcon: 'cart plus'
                    message: "#{@title} added"
                    # showProgress: 'bottom'
                    class: 'success'
                    # displayTime: 'auto',
                    position: "bottom center"
                )


    # Template.set_sort_key.events
    #     'click .set_sort': ->
    #         console.log @
    #         Session.set('sort_key', @key)
    #         Session.set('chef_sort_label', @label)
    #         Session.set('chef_sort_icon', @icon)



if Meteor.isServer
    Meteor.publish 'chef_results', (
        picked_ingredients=[]
        picked_sections=[]
        chef_query=''
        view_vegan
        view_gf
        chefs_section=null
        limit=20
        sort_key='_timestamp'
        sort_direction=1
        )->
        # console.log picked_ingredients
        self = @
        match = {model:'chef', app:'nf'}
        if chefs_section 
            match.chefs_section = chefs_section
        if picked_ingredients.length > 0
            match.ingredients = $all: picked_ingredients
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
        if chef_query and chef_query.length > 1
            console.log 'searching chef_query', chef_query
            match.title = {$regex:"#{chef_query}", $options: 'i'}
            # match.tags_string = {$regex:"#{query}", $options: 'i'}

        # match.tags = $all: picked_ingredients
        # if filter then match.model = filter
        # keys = _.keys(prematch)
        # for key in keys
        #     key_array = prematch["#{key}"]
        #     if key_array and key_array.length > 0
        #         match["#{key}"] = $all: key_array
            # console.log 'current facet filter array', current_facet_filter_array

        # console.log 'chef match', match
        # console.log 'sort key', sort_key
        # console.log 'sort direction', sort_direction
        Docs.find match,
            sort:"#{sort_key}":sort_direction
            # sort:_timestamp:-1
            limit: limit
            fields:
                title:1
                image_id:1
                ingredients:1
                model:1
                price_usd:1
                vegan:1
                local:1
                gluten_free:1
            
    Meteor.publish 'chef_search_count', (
        picked_ingredients=[]
        picked_sections=[]
        chef_query
        view_vegan
        view_gf
        )->
        # @unblock()
    
        # console.log picked_ingredients
        self = @
        match = {model:'chef', app:'nf'}
        if picked_ingredients.length > 0
            match.ingredients = $all: picked_ingredients
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
        if chef_query and chef_query.length > 1
            console.log 'searching chef_query', chef_query
            match.title = {$regex:"#{chef_query}", $options: 'i'}
        Counts.publish this, 'chef_counter', Docs.find(match)
        return undefined

    Meteor.publish 'chef_facets', (
        picked_ingredients=[]
        picked_sections=[]
        chef_query=null
        view_vegan=false
        view_gf=false
        chefs_section=null
        doc_limit=20
        doc_sort_key
        doc_sort_direction
        view_delivery
        view_pickup
        view_open
        )->
        # console.log 'dummy', dummy
        # console.log 'query', query
        # console.log 'picked ingredients', picked_ingredients

        self = @
        match = {app:'nf'}
        match.model = 'chef'
        if chefs_section 
            match.chefs_section = chefs_section
        if view_vegan
            match.vegan = true
        if view_gf
            match.gluten_free = true
        # if view_local
        #     match.local = true
        if picked_ingredients.length > 0 then match.ingredients = $all: picked_ingredients
        if picked_sections.length > 0 then match.menu_section = $all: picked_sections
            # match.$regex:"#{chef_query}", $options: 'i'}
        if chef_query and chef_query.length > 1
            console.log 'searching chef_query', chef_query
            match.title = {$regex:"#{chef_query}", $options: 'i'}
            # match.tags_string = {$regex:"#{query}", $options: 'i'}
        #
        #     Terms.find {
        #         title: {$regex:"#{query}", $options: 'i'}
        #     },
        #         sort:
        #             count: -1
        #         limit: 42
            # tag_cloud = Docs.aggregate [
            #     { $match: match }
            #     { $project: "tags": 1 }
            #     { $unwind: "$tags" }
            #     { $group: _id: "$tags", count: $sum: 1 }
            #     { $match: _id: $nin: picked_ingredients }
            #     { $match: _id: {$regex:"#{query}", $options: 'i'} }
            #     { $sort: count: -1, _id: 1 }
            #     { $limit: 42 }
            #     { $project: _id: 0, name: '$_id', count: 1 }
            #     ]

        # else
        # unless query and query.length > 2
        # if picked_ingredients.length > 0 then match.tags = $all: picked_ingredients
        # # match.tags = $all: picked_ingredients
        # # console.log 'match for tags', match
        section_cloud = Docs.aggregate [
            { $match: match }
            { $project: "menu_section": 1 }
            { $group: _id: "$menu_section", count: $sum: 1 }
            { $match: _id: $nin: picked_sections }
            # { $match: _id: {$regex:"#{chef_query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: 20 }
            { $project: _id: 0, name: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
        
        section_cloud.forEach (section, i) =>
            # console.log 'queried section ', section
            # console.log 'key', key
            self.added 'results', Random.id(),
                title: section.name
                count: section.count
                model:'section'
                # category:key
                # index: i


        ingredient_cloud = Docs.aggregate [
            { $match: match }
            { $project: "ingredients": 1 }
            { $unwind: "$ingredients" }
            { $match: _id: $nin: picked_ingredients }
            { $group: _id: "$ingredients", count: $sum: 1 }
            { $sort: count: -1, _id: 1 }
            { $limit: 20 }
            { $project: _id: 0, title: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }

        ingredient_cloud.forEach (ingredient, i) =>
            # console.log 'ingredient result ', ingredient
            self.added 'results', Random.id(),
                title: ingredient.title
                count: ingredient.count
                model:'ingredient'
                # category:key
                # index: i


        self.ready()





if Meteor.isClient
    Template.chef_card.onCreated ->
        # @autorun => Meteor.subscribe 'model_docs', 'food'
    Template.chef_card.events
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

    Template.chef_card.helpers
        chef_card_class: ->
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
        