xquery version "3.0";

(:~
 : Origami transformer example: XQuery wiki example
 :
 : This is a port of the example.
 : It shows a style of templating that is very similar to
 : XSLT. It is preferable to use `xf:template` for this type
 : of transformation.
 :
 : @see http://en.wikibooks.org/wiki/XQuery/Transformation_idioms
 :
 : TODO: Currently runs at about 1.5 secs which is terrible.
 :       When running from basexgui it also gets increasingly slower.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:
 : Required to avoid whitespace 'chopping' around inline elements
 : This has the consequence that too much whitespace will be inserted
 : into output.
 :)
declare option db:chop 'false';

let $parent := 
    function($node) {
        $node/ancestor::*[not(self::xf:*)][1] }
   
let $input :=
    xf:xml-resource(file:base-dir() || 'coupland.xml')

let $transform := xf:transform((

    xf:match('websites', function($websites as element(websites)) {
        <html>
            <head>
               <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
               <title>Web Sites by Coupland</title>
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/screen.css" type="text/css" media="screen, projection"/>
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/print.css" type="text/css" media="print"/>
               <!--[if IE ]><link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/ie.css" type="text/css" media="screen, projection" /><![endif]-->
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/eXist/transformation/screen.css" type="text/css" media="screen"/>
            </head>
            <body>
                <div class="container">{
                    for $category in $websites/category
                    order by $category/class
                    return
                        <div>
                            <div class="span-10">{ xf:apply($category) }</div>
                            <div class="span-14 last">{
                                for $site in $websites/sites/site[category=$category/class]
                                order by ($site/sortkey,$site/name)[1]
                                return
                                    xf:apply($site)
                            }</div>
                            <hr />
                        </div>
                }</div>  
             </body>
        </html>           
    }),

    xf:match('category[not(../site)]', function($category as element(category)) {
        <div>{ $category/@*, xf:apply($category/node()) }</div>
    }),
    
    xf:match('class', ()),

    xf:match('description', function($description as element(description)) { 
        <div>{ $description/@*, xf:apply($description/node()) }</div> 
    }),
    
    xf:match('em', function($em as element(em)) {
        <em>{ $em/@*, xf:apply($em/node()) }</em>
    }),

    xf:match('hub', function($hub as element(hub)) {
        <hub>{ $hub/@*, xf:apply($hub/node()) }</hub>
    }),

    xf:match('image', function($image as element(image)) {
        <div><img src="{ $image }"/></div>
    }),
    
    xf:match('name', function($name as element(name)) {
        if ($parent($name)/site) then
            <span style="font-size: 16pt">{ 
                $name/@*, xf:apply($name/node()) 
            }</span>
        else
            <h1>{ $name/@*, xf:apply($name/node()) }</h1>
    }),
    
    xf:match('p', function($p as element(p)) {
        <p>{ $p/@*, xf:apply($p/node()) }</p>    
    }),
    
    xf:match('q', function($q as element(q)) {
        <q>{ $q/@*, xf:apply($q/node()) }</q>
    }),

    xf:match('site', function($site as element(site)) {
        <div>
            <div>{ 
                xf:apply($site/name), 
                xf:apply($site/uri) 
            }</div>
            <xf:apply>{ 
                $site/node() except ($site/uri,$site/name) 
            }</xf:apply>
        </div>
    }),

    xf:match('sites', function($sites as element(sites)) {
        for $site in $sites
        order by $site/sortkey
        return
            xf:apply($sites/site)
    }),

    xf:match('sortkey', ()),
    
    xf:match('subtitle', function($subtitle as element(subtitle)) {
        <div>{ $subtitle/@*, xf:apply($subtitle/node()) }</div>
    }),
    
    xf:match('uri', function($uri as element(uri)) {
        <span><a href="{ $uri }">Link</a></span>
    }),
    
    xf:match('*', function($node as element()) {
        xf:apply($node/node())
    })
        
))

return $transform($input)

(:

    > basex -V -r10 examples/coupland.xq
    Parsing: 62.96 ms (avg)
    Compiling: 50.45 ms (avg)
    Evaluating: 1226.13 ms (avg)
    Printing: 3.07 ms (avg)
    Total Time: 1342.61 ms (avg)
    
 :) 
