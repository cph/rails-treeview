angular.module("tree-view", ['ui.tree'])

.directive("treeView", ["$compile",($compile) ->
  restrict: "E"
  replace: true
  scope:
    collection: "="
    treeTemplate: "="
    urlForNode: "&"
    options: "="
  template: "
    <div class='tree-view'>
      <div ui-tree='options' data-drag-delay='300'>
        <ul ui-tree-nodes ng-model='collection' id='tree-root'>
          <li ng-repeat='node in collection' ui-tree-node ng-include='treeTemplate'></li>
        </ul>
      </div>
    </div>
"
  link: (scope, element, attrs) ->
    hotKeyList = [38,40]
    
    $(document).on 'keydown', (e) ->
      return unless e.keyCode in hotKeyList
      node = scope.state.selectedNode
      scope.$apply ->
        scope.state.selectedNode =
          switch e.keyCode
            when 40
              e.preventDefault()
              scope.nextNode(node)
            when 38
              e.preventDefault()
              scope.prevNode(node)

    scope.options = {} unless scope.options
    nodesById = {}

    scope.state =
      selectedNode: undefined

    scope.options["dropped"] = (e) ->
      parent = e.dest.nodesScope.$parent.$modelValue
      currentNode = e.source.nodeScope.$modelValue
      currentNode.parentId = if parent then parent.id else null

    scope.getNodeById = (nodeId) ->
      nodesById[nodeId]

    scope.getParentOf = (node) ->
      if node and node.parentId then scope.getNodeById(node.parentId) else undefined

    scope.getSiblingsOf = (node) ->
      parent = scope.getParentOf(node)
      if parent then parent.children else scope.collection

    scope.prevSiblingOf = (node) ->
      collection = scope.getSiblingsOf(node)
      index = collection.indexOf(node)
      collection[index - 1]

    scope.nextSiblingOf = (node) ->
      collection = scope.getSiblingsOf(node)
      index = collection.indexOf(node)
      collection[index + 1]

    scope.hasChildren = (node) ->
      node.children and node.children.length > 0

    scope.prevNode = (node) ->
      return lastNodeOf(scope.collection) unless node
      parent = scope.getParentOf(node)
      prevSibling = scope.prevSiblingOf(node)
      return parent unless prevSibling
      while scope.hasChildren(prevSibling)
        prevSibling = lastNodeOf(prevSibling.children)
      prevSibling

    scope.nextNode = (node) ->
      return firstNodeOf(scope.collection) unless node
      return firstNodeOf(node.children) if scope.hasChildren(node)
      while node and not (nextSibling = scope.nextSiblingOf(node))
        node = scope.getParentOf(node)
      nextSibling

    scope.selectNode = (node) ->
      return unless scope.options.selectable
      scope.state.selectedNode = node

    scope.hotKeys = (e) ->
      $input = element.find("input.rename-node")
      node = nodesById[$input.data("id")]
      cancelRename($input) if e.keyCode is 27
      commitRename(node) if e.keyCode is 13
      return

    scope.beginRename = (node, nodeContainer) ->
      return unless scope.options.renameable
      inputHTML = 
        "<input data-id='#{node.id}' ng-keyup='hotKeys($event)' class='rename-node' type='text' value='#{node.title}'></input>"
      nodeContainer.children(":first").hide()
      $compile(inputHTML) scope, (cloned, scope) ->
        nodeContainer.prepend cloned
        nodeContainer.find("input:first").focus()
      return

    cancelRename = ($input) ->
      endRename($input)

    commitRename = (node) ->
      return if element.find("input.rename-node").length < 1
      $input = element.find("input.rename-node")
      renamedEvent = scope.$emit "nodeRenamed"
      node.title = $input.val() unless renamedEvent.defaultPrevented
      endRename($input, node)

    endRename = ($input, node) ->
      hiddenNodeHTML = $("[ui-tree-node]").find(":hidden")
      $input.remove()
      hiddenNodeHTML.show()

    firstNodeOf = (collection) ->
      return collection[0]

    lastNodeOf = (collection) ->
      return collection[collection.length - 1]

    setNodesById = (collection) ->
        for node in collection
          nodesById[node.id] = node
          if node.children?
            setNodesById(node.children)

    setNodeTemplates = (collection) ->
      for node in collection
        node.templateUrl = scope.urlForNode(node: node) || ""
        if node.children?
          setNodeTemplates(node.children)

    runOnce  = scope.$watch 'collection', (collection) ->
      return unless collection
      setNodesById(collection)
      setNodeTemplates(collection)
      runOnce()

    return
  ])
