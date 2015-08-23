xquery version "3.1";

module namespace μ = 'http://xokomola.com/xquery/origami/mu';

import module namespace u = 'http://xokomola.com/xquery/origami/utils' at 'utils.xqm'; 

declare namespace xsl = 'http://www.w3.org/1999/XSL/Transform';
declare namespace xs = 'http://www.w3.org/2001/XMLSchema';

declare %private variable $μ:ns := 'http://xokomola.com/xquery/origami/mu';

(:~ 
 : Origami μ-documents
 :)

(: Reading from external entities :)

declare function μ:read-xml($uri as xs:string?)
as document-node()?
{
    doc($uri)
};

(:~
 : XQuery does not support options for controlling the parsing of XML.
 : This function allows the use of proprietary fetch:xml to specify some
 : options to the XML parser.
 :
 : Also there's a difference with fn:doc in that each call fetches a
 : new document and it is discarded after the query ends.
 :
 : For options see: http://docs.basex.org/wiki/Options#Parsing
 :)
declare function μ:read-xml($uri as xs:string?, $options as map(xs:string, item()))
as document-node()?
{
    if (empty($uri))
    then ()
    else fetch:xml($uri, u:select-keys($options, $μ:xml-options))
};

declare %private variable $μ:xml-options :=
    ('chop', 'stripns', 'intparse', 'dtd', 'xinclude', 'catfile', 'skipcorrupt');

(:~
 : Read and parse HTML with the Tagsoup parser (although this could be changed).
 : If Tagsoup is not available it will fallback to parsing well-formed XML.
 :
 : For options see: http://docs.basex.org/wiki/Parsers#TagSoup_Options
 :)
declare function  μ:read-html($uri as xs:string?)
as document-node()?
{
    μ:read-html($uri, map { 'lines': false() })   
};

declare function μ:read-html($uri as xs:string?, $options as map(xs:string, item()))
as document-node()?
{
    μ:parse-html(μ:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

(:~
 : Note that binary or strings can be passed to html:parse, in which case encoding 
 : can be used to override automatic detection.
 : We can also just pass in a seq of strings.
 :)
declare function μ:parse-html($text as xs:string*)
as document-node()?
{
    html:parse(string-join($text, ''))
};

declare function μ:parse-html($text as xs:string*, $options as map(xs:string, item()))
as document-node()?
{
    html:parse(string-join($text, ''), u:select-keys($options, $μ:html-options))
};

(:~
 : TagSoup options not supported by BaseX: 
 : files, method, version, standalone, pyx, pyxin, output-encoding, reuse, help
 : Note that encoding is not passed as text read with $μ:read-text or provided
 : already is in Unicode. 
 :)
declare %private variable $μ:html-options :=
    ('html', 'omit-xml-declaration', 'doctype-system', 'doctype-public', 'nons', 
     'nobogons', 'nodefaults', 'nocolons', 'norestart', 'ignorable', 'empty-bogons', 'any',
     'norootbogons', 'lexical', 'nocdata');

(:~
 : Options:
 :
 : - lines: true() or false()
 : - encoding
 :)
declare function μ:read-text($uri as xs:string?)
as xs:string*
{
    μ:read-text($uri, map { })
};

declare function μ:read-text($uri as xs:string?, $options as map(xs:string, item()))
as xs:string*
{
    (: @see https://github.com/BaseXdb/basex/issues/1181 error when $uri = () :)
    if (empty($uri)) 
    then ()
    else
        let $parse-into-lines := ($options?lines, true())[1]
        let $encoding := $options?encoding
        return
            if ($parse-into-lines)
            then if ($encoding) then unparsed-text-lines($uri, $encoding) else unparsed-text-lines($uri) 
            else if ($encoding) then unparsed-text($uri, $encoding) else unparsed-text($uri)
};

declare function μ:read-json($uri as xs:string?)
as item()?
{
    μ:read-json($uri, map {})
};

declare function μ:read-json($uri as xs:string?, $options as map(xs:string, item()))
as item()?
{
    json-doc($uri, u:select-keys($options, $μ:xml-options))
};

(:~
 : Options:
 :
 : - liberal: true() or false() [default, RFC7159 parsing]
 : - unescape: true() or false() [default true()]
 : - duplicates: reject, use-first, use-last [default use-last]
 :
 : See: http://www.w3.org/TR/xpath-functions-31/#func-parse-json
 :)
declare function μ:parse-json($text as xs:string*)
as item()?
{
    parse-json(string-join($text,''))
};

declare function μ:parse-json($text as xs:string*, $options as map(xs:string, item()))
as item()?
{
    parse-json(string-join($text,''), $options?($μ:json-options))
};

declare %private variable $μ:json-options :=
    ('liberal', 'unescape', 'duplicates');

(:~
 : Options:
 :
 : - encoding (for text decoding)
 : - separator: comma, semicolon, tab, space or any single character (default comma)
 : - lax: yes, no (yes) lax approach to parsing qnames to json names
 : - quotes: yes, no (yes)
 : - backslashes: yes, no (no)
 :
 : TODO: check which options are only meant for serialization.
 :)
declare function μ:read-csv($uri as xs:string?)
as array(*)*
{
    μ:read-csv($uri, map {})
};

declare function μ:read-csv($uri as xs:string?, $options as map(xs:string, item()))
as array(*)*
{
    μ:parse-csv(μ:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

declare function μ:parse-csv($text as xs:string*)
as array(*)*
{
    μ:parse-csv($text, map {})
};

declare function μ:parse-csv($text as xs:string*, $options as map(xs:string, item()))
as array(*)*
{
    let $parse-options := map:merge((u:select-keys($options, $μ:csv-options), map { 'format': 'map' }))
    return
        μ:csv-normal-form(csv:parse(string-join($text,'&#10;'), $parse-options))
};

(: ignore format option (only supported normalized form), header is dealt with in μ:csv-object :)
declare %private variable $μ:csv-options :=
    ('separator', 'lax', 'quotes', 'backslashes');

(:~
 : BaseX csv:parse returns a map with keys, this turns it into
 : a sequence of arrays (each array corresponds with a row)
 :)
declare %private function μ:csv-normal-form($csv)
{
    for $i in map:keys($csv)
    return
        array { $csv($i) }
};

(: Parsing into μ nodes :)

(:~
 : The main function for converting sequence of items that are not yet
 : μ nodes into the proper format.
 : Arrays and maps will be written into explicit nodes.
 : In most cases however constructing μ nodes is done manually as this
 : is just a data-structure.
 : This function is most useful for converting XML nodes to μ nodes.
 :
 : Note that this may return a fragment only.
 :)
declare function μ:nodes($items as item()*)
as item()*
{
    $items ! μ:node(.)
};


declare function μ:node($item as item())
{
    μ:node($item, map {})
};

declare function μ:node($item as item(), $rules as map(*))
as item()
{
    typeswitch($item)
    
    case element()
    return
        array { 
            name($item), 
            if ($item/@*) 
            then 
                map:merge((
                    for $a in $item/@* except $item/@μ:node
                    return map:entry(name($a), data($a)),
                    if ($item/@μ:node and map:contains($rules, string($item/@μ:node)))
                    then map:entry('μ:handler', $rules(string($item/@μ:node)))
                    else ()
                ))
            else (),
            $item/node() ! μ:node(., $rules)
        }

    case text() 
    return string($item)
    
    case xs:anyAtomicType
    return $item
    
    case array(*)
    return
        if (μ:tag($item) eq 'μ:object')
        then
            $item
        else
            array {
                'μ:array',
                $item?* ! μ:node(., $rules)
            }
            
    case map(*)
    return
        array {
            'μ:map',
            for $k in map:keys($item)
            return
                [$k, $item($k) ! μ:node(., $rules)]
        }
        
    default
    return ()
};

(:~
 : Get the nested objects inside the datastructure.
 :)
declare function μ:objects($mu as item()?)
{
    let $inner := function($el) {
        if (μ:tag($el) = 'μ:object')
        then $el
        else
            for $item in μ:content($el)
            where $item instance of array(*)
            return μ:objects($item)
    }
    let $outer := function($seq) { $seq }
    return
        u:walk($inner, $outer, $mu)
};

declare %private function μ:typed-object($type as xs:string, $content as item()*, $attributes as map(xs:string, item()))
as array(*)?
{
    let $attributes := map:merge(($attributes, map:entry('μ:type', $type)))
    where count($content) gt 0
    return
        ['μ:object', $attributes, $content]
};

declare function μ:json-object($json-xdm as item()?)
as array(*)?
{
    μ:json-object($json-xdm, map {})
};

declare function μ:json-object($json-xdm as item()?, $attributes as map(xs:string, item()))
as array(*)?
{
    μ:typed-object('json', $json-xdm, $attributes)
};

declare function μ:csv-object($csv-xdm as array(*)*)
as array(*)?
{
    μ:csv-object($csv-xdm, map {})
};

declare function μ:csv-object($csv-xdm as array(*)*, $attributes as map(xs:string, item()))
as array(*)?
{
    μ:typed-object('csv', $csv-xdm, $attributes)
};

declare function μ:text-object($text as xs:string*)
as array(*)?
{
    μ:text-object($text, map {})
};

declare function μ:text-object($text as xs:string*, $attributes as map(xs:string, item()))
as array(*)?
{
    
    μ:typed-object('text', $text, $attributes)
};

(: Object to XML transformers: provides default rendering of basic objects. :)
(: TODO: merge this with μ:doc :) 
declare function μ:object-doc($object as array(*))
{
    switch (μ:attributes($object)?('μ:type'))
    
    case 'text'
    return
        for $line in μ:content($object)
        return
            ['p', $line]
            
    case 'csv'
    return
        ['table',
            for $row in μ:content($object)
            return
                ['tr',
                    for $cell in $row?*
                    return
                        ['td', $cell]
                ]
        ]
        
    case 'json'
    return 'JSON'
    
    default
    return $object
};

(: Serializing :)

declare function μ:xml($mu as item()*)
as node()*
{
    μ:to-xml($mu, μ:qname-resolver())
};

declare function μ:xml($mu as item()*, $name-resolver as function(*)) 
as node()*
{
    μ:to-xml($mu, $name-resolver)
};

declare function μ:json($mu as item()*)
as xs:string
{
    μ:json($mu, function($name) { $name })
};

declare function μ:json($mu as item()*, $name-resolver as function(*)) 
as xs:string
{
    serialize(
        μ:to-json(if (count($mu) gt 1) then array { $mu } else $mu, $name-resolver), 
        map { 'method': 'json' }
    )
};

(: General :)

declare function μ:apply($mu as item()*)
as item()*
{
    μ:apply($mu, [])
};

declare function μ:apply($mu as item()*, $args as item()*) 
as item()*
{
    (: if there's one argument given wrap it in an array (for fn:apply) :)
    let $args := if ($args instance of array(*)) then $args else [ $args ]
    for $item in $mu
    return
        μ:to-apply($item, $args)
};

(: TODO: bug in attribute map handling, currently creates text nodes not attributes :)
declare %private function μ:to-apply($mu as item(), $args as array(*)) 
as item()*
{
    typeswitch ($mu)
    
    case array(*) 
    return
        let $name := array:head($mu)
        return
            if (empty($name)) 
            then
                for $item in array:tail($mu)?* return μ:to-apply($item, $args)    
            else
                array:fold-left($mu, [], 
                    function($a,$b) {
                        if (empty($b)) 
                        then $a
                        else
                            array:append($a, for $item in $b return μ:to-apply($item, $args))
                    }
                )
                
    case map(*) 
    return
        map:for-each($mu, 
            function($k,$v) {
                typeswitch ($v)
                case function(*)
                return map:entry($k, apply($v, $args))
                default
                return $v
            }
        )
        
    case function(*) 
    return for $item in apply($mu, $args) return μ:to-apply($item, $args)
    
    default 
    return $mu
};

(: TODO: prefix attribute names with @?, plus general improvement :)
declare %private function μ:to-json($mu as item()*, $name-resolver as function(*))
as item()*
{
    for $item in $mu
    return
        typeswitch ($item)
        
        case array(*)
        return
            let $tag := μ:tag($item)
            let $atts := μ:attributes($item)
            let $children := μ:content($item)
            return
                switch ($tag)
                
                case 'μ:json'
                return μ:to-json(($atts,$children), $name-resolver)
                
                case 'μ:array'
                return array { μ:to-json($children, $name-resolver) }
                
                case 'μ:obj'
                return map:merge(
                    for $child in $children
                    return μ:to-json($children, $name-resolver)
                )
                
                default
                return map:entry($tag, μ:to-json(($atts, $children), $name-resolver))
                
        case map(*)
        return 
            map:merge(
                map:for-each($item, 
                    function($a,$b) { 
                        map:entry(concat('@',$a), μ:to-json($b, $name-resolver)) }))
                        
        case function(*) return ()
        
        (: FIXME: I think this should be using to-json as well :)
        case node() 
        return μ:nodes($item)
        
        default 
        return $item
};

(: TODO: namespace handling, especially to-attributes :)
declare %private function μ:to-xml($mu as item()*, $name-resolver as function(*))
as node()*
{
    for $item in $mu
    return
        typeswitch ($item)
        
        case array(*) 
        return 
            if (μ:tag($item) = 'μ:object')
            then μ:to-xml((μ:attributes($item)?xml, μ:object-doc(?))[1]($item), $name-resolver)
            else μ:to-element($item, $name-resolver)
        
        case map(*) return  μ:to-attributes($item, $name-resolver)
        case function(*) return ()
        case empty-sequence() return ()
        case node() return $item
        default return text { $item }
};

(: TODO: need more common map manipulation functions :)
(: TODO: change ns handling to using a map to construct them at the top (sane namespaces) :)
declare %private function μ:to-element($mu as array(*), $name-resolver as function(*))
as item()*
{
    let $tag := μ:tag($mu)
    let $atts := μ:attributes($mu)
    let $ns-atts := map:merge((map:for-each($atts, function($k, $v) { if (starts-with($k, 'xmlns:')) then map:entry($k, $v) else () })))
    let $atts := map:merge((map:for-each($atts, function($k, $v) { if (starts-with($k, 'xmlns:')) then () else map:entry($k, $v) })))
    let $content := μ:content($mu)
    where $tag
    return
        element { $name-resolver($tag) } {
            namespace μ { $μ:ns },
            μ:to-attributes($atts, $name-resolver),
            fold-left($content, (),
                function($n, $i) {
                    ($n, μ:to-xml($i, $name-resolver))
                }
            )
        }
};

declare %private function μ:to-attributes($mu as map(*)?, $name-resolver as function(*))
as attribute()*
{
    map:for-each($mu, 
        function($k,$v) {
            (: should not add default ns to attributes if name has no prefix :)
            attribute { if (contains($k,':')) then $name-resolver($k) else $k } { 
                data(
                    typeswitch ($v)
                    case array(*) return $v
                    case map(*) return $v
                    case function(*) return ()
                    default return $v
                )
            }
        })
};

declare function μ:html-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, μ:ns(), 'http://www.w3.org/1999/xhtml')
};

declare function μ:qname-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, μ:ns(), ())
};

declare function μ:qname-resolver($ns-map as map(*))
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, ())
};

declare function μ:qname-resolver($ns-map as map(*), $default-ns as xs:string)
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, $default-ns)
};

(:~
 : As XQuery doesn't allow access to namespace nodes (as XSLT does)
 : construct them indirectly via QName#2.
 :)

declare function μ:qname($name as xs:string)
as xs:QName
{
    QName((), $name)
};

declare function μ:qname($name as xs:string, $ns-map as map(*))
as xs:QName
{
    μ:qname($name, $ns-map, ())
};

declare function μ:qname($name as xs:string, $ns-map as map(*), $default-ns as xs:string?)
as xs:QName
{
    if (contains($name, ':')) 
    then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := $ns-map($prefix)
        return
            if ($ns = $default-ns) 
            then QName($ns, $local)
            else QName($ns, concat($prefix, ':', $local))
    else
        if ($default-ns) 
        then QName($default-ns, $name)
        else QName((), $name)
};

declare function μ:ns()
as map(*)
{
    μ:ns(map {})
};

declare function μ:ns($ns-map as map(*))
as map(*)
{
    map:merge((
        $ns-map,
        for $ns in doc(concat(file:base-dir(),'/nsmap.xml'))/nsmap/*
        return
            map:entry(string($ns/@prefix), string($ns/@uri))
    ))
};

declare function μ:mix($mu as array(*)?) 
as array(*)?
{
    if (empty($mu)) 
    then ()
    else [(), $mu]
};

declare function μ:head($mu as array(*)?)
as item()*
{
    if (empty($mu)) 
    then ()
    else array:head($mu)
};

declare function μ:tail($mu as array(*)?)
as item()*
{
    tail($mu?*)
};

declare function μ:tag($mu as array(*)?)
as xs:string?
{
    if (empty($mu)) 
    then ()
    else array:head($mu)
};

declare function μ:content($mu as array(*)?)
as item()*
{
    if (array:size($mu) > 0) then
        let $c := array:tail($mu)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*)) 
            then array:tail($c)?*
            else $c?*
    else
        ()
};

declare function μ:attributes($mu as array(*)?)
as map(*)?
{
    if (array:size($mu) gt 1 and $mu(2) instance of map(*)) 
    then $mu(2) 
    else map {}
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function μ:size($mu as array(*)?)
as item()*
{
    count(μ:content($mu))
};

(:~
 : Create a template using a node sequence. This template
 : does not have template rules and does not accept any 
 : context arguments. Effectively this will return the
 : template node sequence unmodified.
 :) 
declare function μ:template($template as item()*)
as function(*)
{
    μ:template($template, (), function() { () })
};

(:~
 : Create a template using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function μ:template($template as item()*, $rules as array(*)*)
as function(*)
{
    μ:template($template, $rules, function() { () })
};

(:~
 : Create a template using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
(: TODO: can't we simplify on always having an on array arg function as context corresp. to apply :)

declare function μ:template(
$template as item()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    let $compiled-rules := μ:compile-rules($rules)  
    let $compiled-template := μ:compile-template($template, $compiled-rules)
    return
        let $transformer := μ:transform($compiled-template, ?)
        return
            switch (function-arity($context))                
            case 0 return function() { $transformer(()) }
            case 1 return function($a) { $transformer($context($a)) }
            case 2 return function($a,$b) { $transformer($context($a,$b)) }
            case 3 return function($a,$b,$c) { $transformer($context($a,$b,$c)) }
            case 4 return function($a,$b,$c,$d) { $transformer($context($a,$b,$c,$d)) }
            case 5 return function($a,$b,$c,$d,$e) { $transformer($context($a,$b,$c,$d,$e)) }
            case 6 return function($a,$b,$c,$d,$e,$f) { $transformer($context($a,$b,$c,$d,$e,$f)) }
            default return 
                error(μ:ContextArityError, 
                    'μ:template does not support context function arity &gt; 6')
};

(: TODO: smarter treatment of rule tail. :)
(: ['p', ()]   delete p elements :)
(: ['p', <foobar/>] replace p with foobar :)
(: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare function μ:compile-rules($rules as array(*)*)
as map(*)?
{
    if (count($rules) gt 0)
    then
        map:merge((
            for $rule in $rules
            let $selector := array:head($rule)
            let $handler := $rule(2)
            return
                map:entry($selector, $handler)
        ))
    else
        ()
};

declare function μ:compile-template($template as array(*), $rules as map(*)?)
as array(*)?
{
    if (empty($rules))
    then μ:node($template)
    else μ:node(xslt:transform(μ:xml($template), μ:xml(μ:compile-transformer($rules))), $rules)
};

(:~
 : Create a template snippet using a node sequence. This template
 : does not have template rules and does not accept any 
 : context arguments. Effectively this will return the
 : template node sequence unmodified.
 :
 : TODO: consider how this can get something like μ:select (eg. get a bunch of nodes into a map)?
 :) 
declare function μ:snippet($template as node()*)
as function(*)
{
    μ:snippet($template, ())
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function μ:snippet($template as node()*, $rules as array(*)*)
as function(*)
{
    μ:snippet($template, $rules, function() { () })
};

(:~
 : Create a template snippet using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
 (: TODO: , μ:compile-extractor#2 :)
declare function μ:snippet(
$template as node()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    μ:template($template, $rules, $context)
};

(: TODO: maybe define $extract as a map of options :)
declare function μ:compile-transformer($rules as map(*)?)
as array(*)
{
    μ:compile-transformer($rules, false())
};

(: TODO: if I do ns handling differently we could write without the xls: prefix :)
(: TODO: it's a pity we cannot create namespace nodes :)
declare function μ:compile-transformer($rules as map(*)?, $extract as xs:boolean)
as array(*)
{
    ['xsl:stylesheet',
        map { 'version': '1.0', 'xmlns:μ': $μ:ns },
        ['xsl:output', map { 'method': 'xml' }],
        if ($extract) 
        then
            ['xsl:template', map { 'match': 'text()' }]
        else 
            μ:identity-transform(),
        for $selector in map:keys($rules)
        return
            ['xsl:template', map { 'match': $selector },
                ['xsl:copy',
                    ['xsl:copy-of', map { 'select': '@*' }],
                    ['xsl:attribute', map { 'name': 'μ:node' }, $selector],
                    ['xsl:copy-of', map { 'select': 'node()' }]
                ]
            ]
    ]
};

(: TODO: how to handle multiple extractions from the same template? Should we? :)
(: TODO: check if namespace handling is aligned with name resolvers :)
declare function μ:compile-extractor($rules as map(*)?)
as array(*)
{
    μ:compile-transformer($rules, true())
};

declare function μ:identity-transform()
as array(*)+
{
    ['xsl:template', 
        map {
            'priority': -10,
            'match': '@*|*'
        },
        ['xsl:copy',
            ['xsl:apply-templates', 
                map { 'select': '*|@*|text()' }
            ]
        ]
    ],
    ['xsl:template',
        map { 'match': 'processing-instruction()|comment()' }]
};

declare function μ:transform($nodes as item()*, $args)
as item()*
{  
    for $node in $nodes
    return
        typeswitch($node)
        case array(*)
        return
            let $tag := μ:tag($node)
            let $atts := μ:attributes($node)
            let $handler := $atts('μ:handler')
            let $content := μ:content($node)
            return
                if (not(empty($handler)))
                then
                    typeswitch ($handler)
                    case array(*) return $handler
                    case map(*) return $handler
                    case function(*)
                    return μ:transform($handler([$tag, map:remove($atts,'μ:handler'), $content], $args), $args)
                    default return $handler
                else [$tag, $atts, μ:transform($content, $args)]
        default
        return $node
};
