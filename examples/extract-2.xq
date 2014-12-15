xquery version "3.0";

(:~
 : Origami extract example
 :
 : Extract also doesn't return duplicates.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $extract :=
    xf:extract((
        [xf:at('li[@id="last"]'),()], 
        [xf:at('li'),()],
        [xf:at('li[@id="first"]'),()]
    ))
 
let $input :=
  document {
    <ul>
      <li id="first">item 1</li>
      <li>item 2</li>
      <li id="last">item 3</li>
    </ul>    
  }
 
return $extract($input)