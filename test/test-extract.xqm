xquery version "3.1";

(:~
 : Tests for o:apply.
 :
 : In most tests o:xml is used to convert the mu-document to XML. This makes
 : it much easier to read. So, strictly, this is not a unit-test any more.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:extract-nothing() 
{
    unit:assert-equals(
        o:extract(())(<p><x y="10"/></p>),
        (),
        'Nothing'
    ),
    
    unit:assert-equals(
        o:extract(['y'])(<p><x y="10"/></p>),
        (),
        'If no rule matches return nothing'
    )
    
};

declare %unit:test function test:extract-whole-document() 
{
    unit:assert-equals(
        o:xml(o:extract(['*'])(<p><x y="10"/></p>)),
        <p><x y="10"/></p>,
        'Copies every element'
    )
};

(: ISSUE: removing an element doesn't allow a handler to be added :)

declare %unit:test function test:extract-whole-document-with-holes() 
{
    unit:assert-equals(
        o:xml(o:extract(
            ['p', ['c', ()]]
        )(<p>
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
        </p>)),
        <p><x/><y/></p>,
        'Whole document leaving out c elements with content'
    )
};

(:
(:~
 : A context function will typecheck context arguments and return
 : the context that will be available in the template rules ($c).
 :)
declare %unit:test function test:template-context-function() 
{
    unit:assert-equals(
        o:apply(o:extract(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { ['foo', $c] }]
        ), 12),
        ['foo', 12],
        "One argument template"
    ),
    
    unit:assert-equals(
        o:apply(o:extract(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }]
        ), 12),
        <foo>12</foo>,
        "One argument template producing XML element node")
};

:)

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
    o:xml(o:extract($rules)($test:html))
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
        ($test:html//ol[@id='list-1'], $test:html//ol[@id='list-2'], $test:html//ol[@id='list-3']),
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
        o:xml(o:apply(o:extract(
            ['ol', o:wrap(['list']),
                ['li[1]'], ['li', ()]
            ]
        )(
            <ol>
                <li>item 1</li>
                <li>item 2</li>
            </ol>
        ))),
        <list>
            <ol>
                <li>item 1</li>
            </ol>
        </list>,
        'Add list handler'
    )
};
 