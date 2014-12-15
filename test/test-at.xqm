xquery version "3.0";

(:~
 : Tests for xf:at
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~ Test nodes :)
declare variable $test:input := 
        <ul id="xyz">
            <li>item <span class="first">1</span></li>
            <li>item <span>2</span></li>
            <li>item <span class="last"><i>3</i></span></li>
        </ul>;

(:~ Simple selector uses descendents axis :)
declare %unit:test function test:simple-selector() {
    unit:assert-equals(
        xf:at('li')($test:input),
        (<li>item <span class="first">1</span></li>,
         <li>item <span>2</span></li>,
         <li>item <span class="last"><i>3</i></span></li>))
};

(:~ Note that root element is not available for explicit selection :)
declare %unit:test function test:id-select() {
    unit:assert-equals(
        xf:at('@id')($test:input),
        attribute id { 'xyz' })
};

(:~ But when wrapping it in a document node it is :)
declare %unit:test function test:root-select() {
    unit:assert-equals(
        xf:at('/*')(document { $test:input }),
        <ul id="xyz">
            <li>item <span class="first">1</span></li>
            <li>item <span>2</span></li>
            <li>item <span class="last"><i>3</i></span></li>
        </ul>
    )
};

(:~ Transform node sequence :)
declare %unit:test function test:at-do() {
    unit:assert-equals(
        xf:do((
            xf:at('li'),
            function($n) {
                <li>{ count($n) }</li>
            },
            function($n) {
                element n { $n }                
            }
        ))($test:input),
        <n><li>3</li></n>
    )
};

(:~ Transform node sequence :)
declare %unit:test function test:node-sequence() {
    unit:assert-equals(
        xf:at($test:input, 'li', 
            function($n) { 
                text { '[' || upper-case($n) || '.' || position() || ']' } 
            }
        ),
        (text { '[ITEM 1]' },
         text { '[ITEM 2]' },
         text { '[ITEM 3]' })
    )
};
