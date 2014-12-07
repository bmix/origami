xquery version "3.0";

(:~
 : Origami templating.
 :
 : @version 0.4
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami';

import module namespace apply = 'http://xokomola.com/xquery/common/apply'
    at 'apply.xqm';

(:~
 : Load an HTML resource.
 :)
declare function xf:html-resource($url-or-path) {
    if (starts-with($url-or-path,'http:/')) then
        xf:fetch-html($url-or-path)
    else
        xf:parse-html($url-or-path)
};

(:~
 : Load an XML resource.
 :)
declare function xf:xml-resource($url-or-path) {
    doc($url-or-path)
};

(:~
 : Fetch and parse HTML given a URL.
 :)
declare function xf:fetch-html($url) {
    html:parse(fetch:binary($url))
};

(:~
 : Parse HTML from a filesystem path.
 :)
declare function xf:parse-html($path) {
    html:parse(file:read-binary($path))
};

(:~
 : Template data. This is constructed from a transform on the template
 : and executing the slot handlers (match templates) on each matched
 : node from the template.
 :
 : TODO: $tpl should be looked at to determine if fetch or parse should be
 :       invoked (or even doc()). 
 :)
declare function xf:template($tpl, $slots as map(*)*) 
    as node()* {
    xf:transform($slots)($tpl)
};

declare function xf:template($tpl, $slots as map(*)*, $input as node()*)
    as node()* {
    xf:template($tpl, $slots)($input)
};

(:~
 : Transform input, using the specified templates.
 :)
declare function xf:transform($templates as map(*)*, $input as node()*)
    as node()* {
    xf:transform($templates)($input)
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transform($templates as map(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:apply-nodes($nodes, (), $templates)
    }
};

(:~
 : Identity transformer.
 :)
declare function xf:transform() { xf:transform(()) };

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:extract($input as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract($steps)($input)
};

(:~
 : Returns an extractor function that only returns selected nodes 
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract($steps as function(*)*) 
    as function(node()*) as node()* {
    xf:extract-outer($steps)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :)
declare function xf:extract-inner($steps as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:distinct-nodes(innermost(xf:select-nodes($nodes, $steps)))
    }
};

declare function xf:extract-inner($input as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract-inner($steps)($input)
};

(:
 : TODO: when running on 8.0 20141116.135016 or higher then
 :       xf:distinct-nodes() can be removed due to bugfix
 :       remove it after 8.0 is released. 
 :)

(:~
 : Returns an extractor function that returns selected nodes,
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract-outer($steps as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:distinct-nodes(outermost(xf:select-nodes($nodes, $steps)))
    }
};

declare function xf:extract-outer($input as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract-outer($steps)($input)
};


(:~
 : Defines a match template.
 :
 : A template takes a selector string or function and
 : a node transformation function or the items to return as 
 : the template body.
 : Providing invalid matcher returns empty sequence.
 :)
declare function xf:match($selectors, $body) 
    as map(*)? {
    let $select := xf:at($selectors)
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(*) return $body
        default return function($node) { $body }
    where $select instance of function(*) and $body instance of function(*)
    return
        map {
            'select': $select,
            'fn': $body
        }
};

(:~
 : Execute a chain of node selectors.
 :)
declare function xf:at($input, $steps as item()*) {
    xf:at($steps)($input)
};

(:~
 : Compose a select function from a sequence of selector functions or Xpath 
 : expressions.
 :)
declare function xf:at($steps as item()*) 
    as function(node()*) as node()* {
    let $selector := xf:comp-selector($steps)
    return
        function($nodes as node()*) as node()* {
            fold-left($selector, $nodes,
                function($nodes, $step) {
                    for $node in $nodes
                    return
                        $step($node)
                }
            )
        }
};

declare %private function xf:comp-selector($steps as item()*)
    as (function(node()*) as node()*)* {
    for $step in $steps
    return
        if ($step instance of xs:string) then
            xf:xpath-matches($step)
        else
            $step
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do($input as node()*, $fns as function(*)*) 
    as node()* {
    xf:do($fns)($input)
};

(:~
 : Compose a chain of node transformers.
 :)
declare function xf:do($fns as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        fold-left($fns, $nodes,
            function($nodes, $fn) {
                $fn($nodes) 
            }
        ) 
    }
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do-each($input as node()*, $fns as function(*)*) 
    as node()* {
    xf:do-each($fns)($input)
};

(:~
 : Compose a chain of node transformers.
 :)
declare function xf:do-each($fns as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        for $node in $nodes
        return
            fold-left($fns, $node,
                function($node, $fn) {
                    $fn($node) 
                }
            ) 
    }
};

(: ================ node transformers ================ :)

(:~
 : Replace the content (child nodes) of the input node
 :)
declare function xf:content($content as node()*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            $element/@*,
            $content
        }
    }
};

declare function xf:content($element as element(), $content as node()*) 
    as element() {
    xf:content($content)($element)
};

(:~
 : Only replace the content of the input element when
 : the content is not empty.
 :)
declare function xf:content-if($content as node()*)
    as function(element()) as element()* {
    function($element as element()) as element() {
        if (exists($content)) then
            element { node-name($element) } {
                $element/@*,
                $content
            }
        else
            $element
    }
};

declare function xf:content-if($element as element(), $content as node()*)
    as element() {
    xf:content-if($content)($element)
};

(:~
 : Replace the current node.
 :)
declare function xf:replace($replacement as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
            $replacement
    }
};

declare function xf:replace($nodes as node()*, $replacement as node()*) 
    as node()* {
    xf:replace($replacement)($nodes)
};

(:~
 : Only replace the input nodes when the replacement
 : is not empty.
 :)
declare function xf:replace-if($replacement as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        if (exists($replacement)) then
            $replacement
        else
            $nodes
    }
};

declare function xf:replace-if($nodes as node()*, $replacement as node()*)
    as element() {
    xf:replace-if($replacement)($nodes)
};

(:~
 : Inserts nodes before the current node.
 :)
declare function xf:before($before as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($before, $nodes)
    }
};

declare function xf:before($nodes as node()*, $before as node()*)
    as node()* {
    xf:before($before)($nodes)
};

(:~
 : Inserts nodes after the current node.
 :)
declare function xf:after($after as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($nodes, $after)
    }
};

declare function xf:after($nodes as node()*, $after as node()*) 
    as node()* {
    xf:after($after)($nodes)
};

(:~
 : Inserts nodes as first child, before the current content.
 :)
declare function xf:append($append as node()*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            ($element/(@*,node()), $append)
        }
    }
};

declare function xf:append($element as element(), $append as node()*) 
    as element() {
    xf:append($append)($element)
};

(:~
 : Inserts nodes as last child, after the current content.
 :)
declare function xf:prepend($prepend as node()*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            ($element/@*, $prepend, $element/node())
        }
    }
};

declare function xf:prepend($element as element(), $prepend as node()*) 
    as element() {
    xf:prepend($prepend)($element)
};

(:~
 : Returns a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function xf:text()
    as function(node()*) as node()* {
    function($nodes as node()*) as node() {
        text { normalize-space($nodes) }
    }
};

declare function xf:text($node as node()*)
    as text() {
    xf:text()($node)
};

(:~
 : Set attributes using a map.
 :)
declare function xf:set-attr($attr-map as map(*))
    as function(element()) as element() {
    function($element as element()) as element() {
        let $atts := map:for-each($attr-map, 
            function($name,$value) { attribute { $name } { $value } })
        return   
            element { node-name($element) } {
                $atts, $element/@*[not(name(.) = map:keys($attr-map))], $element/node()
            }
    }
};

declare function xf:set-attr($element as element(), $attr-map as map(*)) 
    as element() {
    xf:set-attr($attr-map)($element)
};

(:~
 : Add a class or classes.
 :)
declare function xf:add-class($names as xs:string*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            $element/@*[not(name(.) = 'class')],
            attribute class {
                string-join(
                    distinct-values((
                        tokenize(($element/@class,'')[1],'\s+'), 
                        $names)), 
                    ' ')
            },
            $element/node()
        }
    }
};

declare function xf:add-class($element as element(), $names as xs:string*) 
    as element() {
    xf:add-class($names)($element)
};

(:~
 : Remove a class.
 :)
declare function xf:remove-class($names as xs:string*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            $element/@*[not(name(.) =  'class')],
            let $classes := tokenize(($element/@class,'')[1],'\s+')[not(. = $names)]
            where $classes
            return
                attribute class { string-join($classes,' ') },
            $element/node()
        }
    }
};

declare function xf:remove-class($element as element(), $names as xs:string*) 
    as element() {
    xf:remove-class($names)($element)
};

(:~
 : Remove attributes.
 :)
declare function xf:remove-attr($name as xs:string*)
    as function(element()) as element() {
    function($element as element()) as element() {
        element { node-name($element) } {
            $element/@*[not(name(.) = $name)], $element/node()
        }
    }
};

declare function xf:remove-attr($element as element(), $names as xs:string*) 
    as element() {
    xf:remove-attr($names)($element)
};

(:~
 : Returns a selector step function that wraps nodes in
 : an element `$node`.
 :)
declare function xf:wrap($element as element())
    as function(node()*) as element() {
    function($nodes as node()*) as element() {
        element { node-name($element) } {
            $element/@*,
            $nodes
        }
    }
};

(:~
 : Wraps `$nodes` in element `$node`.
 :)
declare function xf:wrap($nodes as node()*, $element as element())
    as element() {
    xf:wrap($element)($nodes)
};

(:~
 : Returns a selector step function that removes the outer
 : element and returns only the child nodes.
 :)
declare function xf:unwrap()
    as function(element()) as node()* {
    function($element as element()) as node()* {
        $element/node()
    }
};

declare function xf:unwrap($element as element())
    as node()* {
    xf:unwrap()($element)
};

(: ================ environment ================ :)

(:~
 : Sets up a default environment which can be customized.
 : Represents the default bindings for selecting nodes.
 : The context is set to $nodes and all it's descendant elements.
 : It also sets up a helper function $in to enable proper checks on tokenized
 : (space-delimited) attribute values such as @class.
 :)
declare function xf:environment() {
    map {
        'bindings': function($nodes as node()*) as map(*) {
            map { 
                '': $nodes/descendant-or-self::element(),
                xs:QName('in'): function($att, $token) as xs:boolean {
                    $token = tokenize(string($att),'\s+')
                }
            }
        },
        'query': function($selector as xs:string) {
            'declare variable $in external; ' || $selector
        }
    }
};

(: ================ internal functions ================ :)

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy-nodes($nodes as node()*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply-nodes($node/(@*, node()), (), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*,
                xf:copy-nodes($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:copy-nodes($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Looks in the $context to find a template that was matched by this
 : node. First one found (most-specific) wins.
 :)
declare %private function xf:matched-template($node as node(), $context as map(*)*) 
    as map(*)? {
    if (count($context) gt 0) then
        hof:until(
            function($context as map(*)*) { empty($context) or xf:is-node-in-sequence($node, head($context)('nodes')) },
            function($context as map(*)*) { tail($context) },
            $context
        )[1]
    else
        ()
};

(:~
 : Applies nodes to output, but runs the template node transformer when it
 : encounters a node that was matched.
 :)
declare %private function xf:apply-nodes($nodes as node()*, $context as map(*)*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    let $context := (xf:match-templates($node, $xform), $context)
    let $match := xf:matched-template($node, $context)
    return
        if ($match instance of map(*)) then
            xf:copy-nodes($match('fn')($node), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply-nodes($node/(@*, node()), $context, $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:apply-nodes($node/node(), $context, $xform)
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
 : TODO: maybe rename to xf:apply-rules
 :)
declare function xf:apply($nodes as node()*) 
    as element(xf:apply) { 
    <xf:apply>{ $nodes }</xf:apply> 
};

(:~
 : Return matching nodes.
 :)
declare %private function xf:select-nodes($nodes as node()*, $selectors as function(*)*)
    as node()* {
    for $selector in $selectors
    return
        for $node in $nodes
        return
            $selector($node)
};

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match-node($node as node(), $xform as map(*)*) 
    as map(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                ($is-match instance of map(*) and map:contains($is-match,'nodes'))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            let $matched-nodes := $template('select')($node)
            return
                (
                    if ($matched-nodes) then
                        map:new(($template, map { 'nodes': $matched-nodes }))
                    else
                        ()
                    ,
                    tail($templates)
                )
        },
        $xform
    )[1]
};

(:~
 : Find the first matching template for a node
 : and return a modified template that contains the matched nodes.
 :)
declare %private function xf:match-template($node as node(), $xform as map(*)*) 
    as map(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                ($is-match instance of map(*) and map:contains($is-match,'nodes'))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            let $matched-nodes := $template('select')($node)
            return
                (
                    if ($matched-nodes) then
                        map:new(($template, map { 'nodes': $matched-nodes }))
                    else
                        ()
                    ,
                    tail($templates)
                )
        },
        $xform
    )[1]
};

(:~
 : Find all templates matched by this node and adds the matched nodes
 : to the templates.
 :)
declare %private function xf:match-templates($node as node(), $xform as map(*)*) 
    as map(*)* {
    fold-left(
        $xform, (),
        function($matched-templates as map(*)*, $template as map(*)) {
            let $matched-nodes := $template('select')($node)
            return
                if ($matched-nodes) then
                    ($matched-templates, map:new(($template, map { 'nodes': $matched-nodes })))
                else
                    $matched-templates
        }
    )
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 :)
declare %private function xf:xpath-matches($selector as xs:string) 
    as function(node()*) as node()* {
    xf:xpath-matches($selector, xf:environment())
};

declare %private function xf:xpath-matches($selector as xs:string, $env as map(*)) 
    as function(node()*) as node()* {
    let $query := $env('query')($selector)
    let $bindings := $env('bindings')
    return
        function($nodes as node()*) as node()* {
            xquery:eval($query, $bindings($nodes))
        }
};

(:~
 : Returns only distinct nodes.
 : @see http://www.xqueryfunctions.com/xq/functx_distinct-nodes.html
 :)
declare %private function xf:distinct-nodes($nodes as node()*) 
    as node()* {
    for $seq in (1 to count($nodes))
    return $nodes[$seq][
        not(xf:is-node-in-sequence(.,$nodes[position() < $seq]))]
};
 
(:~
 : Is node defined in seq?
 : @see http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html
 :)
declare %private function xf:is-node-in-sequence($node as node()?, $seq as node()*)
    as xs:boolean {
    some $nodeInSeq in $seq satisfies $nodeInSeq is $node
};

(:~
 : Partition a sequence into an array of sequences $n long.
 : This is used to build rules that consist of a selector (xf:at) and
 : a body (xf:do).
 :)
declare function xf:partition($n as xs:integer, $seq) as array(*)* {
    if (not(empty($seq))) then
        for $i in 1 to (count($seq) idiv $n) + 1
        where count($seq) > ($i -1) * $n
        return
            array { subsequence($seq, (($i -1) * $n) + 1, $n) }
    else
        ()
};
