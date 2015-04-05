xquery version "3.0";

(:~ 
 : Example: basex -V -r 100 -b rows=10000 examples/create-table-origami.xq 
 :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare variable $rows as xs:integer external := 10;

let $input :=
  <result>{
     for $i in (1 to $rows)
     return
       <record name="foo" age="{ $i }"/> 
  }
  </result>
let $rec := function($rec) { ($rec/@name, ($rec/@age,'unknown')[1]) }
let $table-builder := function($model) {
    xf:do([
        xf:at(
           ['record', 
             $model,
             xf:each(
               [xf:text(), xf:wrap(<td/>)]
             ), 
             xf:wrap(<tr/>) 
           ]
        ),
        xf:wrap(<table/>)])
    }
let $table := $table-builder($rec)
return
    $table($input)
