xquery version "3.1";

(:~
 : Examples for μ-documents
 :)

module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare function ex:files($dir as xs:string)
{
    o:xml(
        o:select(
            o:tree-seq(
                file:children($dir),
                function($n) { ends-with($n,'/') },
                file:children#1
            ),
            function($n) { not(ends-with($n,'/')) }
        ) => o:map(o:wrap(['file']))
    )  
};

declare function ex:fileset()
{
    ex:files(file:resolve-path('..', file:base-dir()))
};

declare function ex:fileset($pattern)
{
    o:select(
        ex:files(file:resolve-path('..', file:base-dir())),
        function($n) { matches(o:text($n), $pattern) }
    )
};
