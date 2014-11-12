xquery version "3.0";

(:~
 : Origami extractor example: select code elements from web page.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

let $code := xf:extract(xf:select('code'))

let $input := 
    html:parse(fetch:binary("http://xokomola.com/2014/11/10/xquery-origami-1.html"))
    
return $code($input)
