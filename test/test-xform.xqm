xquery version "3.1";

(:~
 : Tests for o:xform()
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:extract-nothing() 
{
    unit:assert-equals(
        o:doc(<p><x y="10"/></p>, o:xform()),
        ['p', ['x', map { 'y': '10' }]],
        'No argument = identity'
    ),

    (: TODO: is this the correct result? :)
    unit:assert-equals(
        o:doc(<p><x y="10"/></p>,o:xform(())),
        ['p', ['x', map { 'y': '10' }]],
        'Empty argument = identity'
    ),
    
    unit:assert-equals(
        o:doc(<p><x y="10"/></p>, o:xform(['y'])),
        (),
        'If no rule matches return nothing'
    )   
};

declare %unit:test function test:extract-whole-document() 
{
    unit:assert-equals(
        o:xml(<p><x y="10"/></p>, o:xform(['*'])),
        <p><x y="10"/></p>,
        'Copies every element'
    )
};

(: ISSUE: removing an element doesn't allow a handler to be added :)

declare %unit:test function test:extract-whole-document-with-holes() 
{
    unit:assert-equals(
        o:doc(
            <p>
                <x>
                    <c>
                        <xxx/>
                    </c>
                </x>
                <y>
                    <c>
                        <yyy/>
                    </c>
                </y>
            </p>,
            o:xform(['p', ['c', ()]])
        ),
        ["p", ["x"], ["y"]],
        'Whole document leaving out c elements'
    )
};

(:~
 : When the second argument of o:doc is not an xform it is implicitly converted 
 : into one.
 :)
declare %unit:test function test:implicit-xform()
{
      unit:assert-equals(
        o:xml(o:doc(<x/>,['x'])),
        <x/>
      )  
};

(:~
 : A context function will typecheck context arguments and return the context 
 : that will be available in the template rules ($c).
 :)
declare %unit:test function test:context-function() 
{
    unit:assert-equals(
        o:apply(
          o:doc(
            <x><p><y/></p></x>,
            o:xform(['p', function($n,$c) { ['foo', $c] }])
          ), 
          [12]
        ),
        ['foo', 12],
        'One argument template'
    ),
    
    unit:assert-equals(
        o:apply(
          o:doc(
            <x><p><y/></p></x>,
            o:xform(['p', function($n,$a,$b) { <foo>{ $a,$b }</foo> }])
          ),
          [12,13]
        ),
        <foo>12 13</foo>,
        'One argument template producing XML element node')
};

declare variable $test:html :=
    <html>
        <head>
            <title>title</title>
        </head>
        <body>
            <div id="content">
                <table id="table-1">
                    <tr>
                        <th>A</th><th>B</th><th>C</th>
                    </tr>
                    <tr>
                        <td><a href="a-link">10</a></td><td>20</td><td>30</td>
                    </tr>
                </table>
                <ol id="list-1">
                    <li>item 1</li>
                    <li>item 2</li>
                    <li>item 3</li>
                </ol>
                <div id="sub-content">
                    <ol id="list-2">
                        <li>item 3</li>
                        <li>item 4</li>
                        <li>item 5</li>
                    </ol> 
                </div>
            </div>
            <ol id="list-3">
                <li>item 6</li>
                <li>item 7</li>
                <li>item 8</li>
            </ol> 
        </body>
    </html>;

declare variable $test:html-no-lists :=
    <html>
        <head>
            <title>title</title>
        </head>
        <body>
            <div id="content">
                <table id="table-1">
                    <tr>
                        <th>A</th><th>B</th><th>C</th>
                    </tr>
                    <tr>
                        <td><a href="a-link">10</a></td><td>20</td><td>30</td>
                    </tr>
                </table>
                <div id="sub-content">
                </div>
            </div>
        </body>
    </html>;

declare function test:xf($rules)
{
    o:xml(o:doc($test:html, o:xform($rules)))
};

declare %unit:test function test:copy-whole-page() 
{
    unit:assert-equals(
        test:xf(['html']),
        $test:html,
        'Take the whole html document'
    )    
};


declare %unit:test function test:extract-lists() 
{
    unit:assert-equals(
        test:xf(
            ['ol']
        ),
        (
            $test:html//ol[@id='list-1'], 
            $test:html//ol[@id='list-2'], 
            $test:html//ol[@id='list-3']
        ),
        'Take all lists in order'
    ),
    unit:assert-equals(
        test:xf(
            ['div', (), ['ol']]
        ),
        ($test:html//ol[@id='list-1'], $test:html//ol[@id='list-2']),
        'Take some lists using nested rule'
    )
};

declare %unit:test function test:remove-lists() 
{
    unit:assert-equals(
        test:xf(
            ['html', ['ol', ()]]
        ),
        $test:html-no-lists,
        'Remove all lists'
    )
};

declare %unit:test function test:remove-all-but-first()
{
    unit:assert-equals(
        test:xf(
            ['ol[@id="list-1"]', ['li[1]'], ['li', ()]]
        ),
        <ol id="list-1">
            <li>item 1</li>
        </ol>,
        'Take first list and remove all but first item'
    )
};

declare %unit:test function test:list-handler()
{
    unit:assert-equals(
        o:xml(
            o:apply(
                o:doc(   
                    <ol>
                        <li>item 1</li>
                        <li>item 2</li>
                    </ol>,
                    o:xform(
                        ['ol', o:wrap(['list']),
                            ['li[1]'], ['li', ()]
                        ]
                    )
                )
            )
        ),
        <list>
            <ol>
                <li>item 1</li>
            </ol>
        </list>,
        'Add list handler'
    )
};
 