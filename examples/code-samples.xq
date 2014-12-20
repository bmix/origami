xquery version "3.0";

(:~
 : Origami extract example
 :
 : Demonstrates how chain of selectors can modify the result. The first
 : selector returns all code elements inside a pre element, removes the
 : outer code element and then wraps it into a code-sample element.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input := 
    xf:fetch-html("http://xokomola.com/2014/11/10/xquery-origami-1.html")

let $code-samples := 
    xf:extract([
        'pre/code', 
        xf:unwrap(), 
        xf:wrap(<code-sample/>)
    ])
    
return $code-samples($input)
