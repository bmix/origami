xquery version "3.0";

(:~
 : Origami transformers.
 :
 : @version 0.3
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami/xform';

(:~
 : Transforms input, using the specified templates.
 :)
declare function xf:xform($templates as map(*)*, $input as node()) as node() {
    xf:xform($templates)($input)
};

(:~
 : Returns a node transformation function.
 :)
declare function xf:xform($templates as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:apply($nodes, $templates)
    }
};

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:xtract($selectors as map(*)*, $input as node()) as node() {
    xf:xtract($selectors)($input)
};

(:~
 : Returns an extractor function that only returns selected nodes.
 :)
declare function xf:xtract($selectors as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:select($nodes, $selectors)
    }
};

(:~
 : Identity transformer.
 :)
declare function xf:xform() { xf:xform(()) };

(:~
 : Defines a template.
 :
 : A template takes a selector string or function and
 : a node transformation function or the items to return as 
 : the template body.
 : Providing invalid matcher returns empty sequence.
 :)
declare function xf:template($match, $body) as map(*)? {
    let $match :=
        typeswitch ($match)
        case xs:string return xf:matches(?, $match)
        case function(item()) as xs:boolean return $match
        default return ()
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(item()) as item()* return $body
        case function(*)* return ()
        default return function($node) { $body }
    where $match instance of function(*) and $body instance of function(*)
    return
        map {
            'match': $match,
            'fn': $body
        }
};

declare function xf:select($match) as map(*)? {
    let $match :=
        typeswitch ($match)
        case xs:string return xf:matches(?, $match)
        case function(item()) as xs:boolean return $match
        default return ()
    where $match instance of function(*)
    return
        map {
            'match': $match,
            'fn': function($node) { $node }
        }
};

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy($nodes as item()*, $xform as map(*)*)
    as item()* {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply(($node/@*,$node/node()), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*,
                xf:copy($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:copy($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Applies node transformations to nodes.
 :)
declare %private function xf:apply($nodes as item()*, $xform as map(*)*)
    as item()* {
    for $node in $nodes
    let $fn := xf:match($node, $xform)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply($node/@*, $xform),
                xf:apply($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:apply($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
 :)
declare function xf:apply($nodes as item()*) 
    as element(xf:apply) { 
    <xf:apply>{ $nodes }</xf:apply> 
};

(:~
 : Look for nodes that match
 :)
declare %private function xf:select($nodes as item()*, $selectors as map(*)*)
    as item()* {
    for $node in $nodes
    let $fn := xf:match($node, $selectors)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $selectors)
        else if ($node instance of element()) then
            xf:select($node/node(), $selectors)   
        else
            ()
};

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match($node as item(), $xform as map(*)*) 
    as function(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                not($is-match instance of map(*))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            return
                (
                    if ($template('match')($node)) then
                        $template('fn')
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
 : Returns true if the string expression matches the $node.
 :)
declare function xf:matches($node as item(), $expr as xs:string) as xs:boolean {
    typeswitch ($node)
    case element() return not($node/self::xf:*) and $expr = (name($node),'*')
    case attribute() return substring-after($expr, '@') = (name($node), '*')
    default return false()
};
