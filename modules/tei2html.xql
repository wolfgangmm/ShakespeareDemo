module namespace tei2="http://exist-db.org/xquery/app/tei2html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function tei2:tei2html($nodes as node()*, $target-layer as xs:string, $target-format as xs:string) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:TEI) return
                tei2:tei2html($node/*, $target-layer, $target-format)
            case element(tei:teiHeader) return
                tei2:header($node)
            case element(tei:text) return
                <div xmlns="http://www.w3.org/1999/xhtml" class="body">{ tei2:tei2html($node//tei:body, $target-layer, $target-format) }</div>
            case element(tei:div) return
                let $level := count($node/ancestor-or-self::tei:div)
                let $type := if ($level eq 2) then "scene" else "act"
                return
                    <div xmlns="http://www.w3.org/1999/xhtml" id="{$node/@xml:id}" class="{$type}">
                        <a name="{$node/@xml:id}"></a>
                        { tei2:tei2html($node/node(), $target-layer, $target-format) }
                    </div>
            case element(tei:head) return
                let $level := count($node/ancestor-or-self::tei:div)
                return
                    element { concat("h", $level) } {
                        tei2:tei2html($node/node(), $target-layer, $target-format)
                    }
            case element(tei:stage) return
                if ($node/ancestor::tei:l) then
                    <span xmlns="http://www.w3.org/1999/xhtml" class="stage">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</span>
                else
                    <p xmlns="http://www.w3.org/1999/xhtml" class="stage">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</p>
            case element(tei:sp) return
                if ($node/tei:l) then
                    <div xmlns="http://www.w3.org/1999/xhtml" class="sp">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</div>
                else
                    <div xmlns="http://www.w3.org/1999/xhtml" class="sp">
                        { tei2:tei2html($node/tei:speaker, $target-layer, $target-format) }
                        <p class="p-ab">{ tei2:tei2html($node/tei:ab, $target-layer, $target-format) }</p>
                    </div>
            case element(tei:l) return
                <p xmlns="http://www.w3.org/1999/xhtml" class="line">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</p>
            case element(tei:ab) return 
                <span xmlns="http://www.w3.org/1999/xhtml" class="ab">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</span>
            case element(tei:speaker) return
                <h5 xmlns="http://www.w3.org/1999/xhtml" class="speaker">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</h5>
            case element(tei:publicationStmt) return
                <div xmlns="http://www.w3.org/1999/xhtml" class="publicationStmt">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</div>
            case element(tei:sourceDesc) return
                <div xmlns="http://www.w3.org/1999/xhtml" class="sourceDesc">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</div>
            case element(tei:p) return 
                <p xmlns="http://www.w3.org/1999/xhtml">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</p>
            case element(tei:title) return
                <em xmlns="http://www.w3.org/1999/xhtml">{ tei2:tei2html($node/node(), $target-layer, $target-format) }</em>
            case element() return
                tei2:tei2html($node/node(), $target-layer, $target-format)
            default return
                $node
};

declare function tei2:header($header as element(tei:teiHeader)) {
    let $titleStmt := $header//tei:titleStmt
    let $pubStmt := $header//tei:publicationStmt
    return
        <div xmlns="http://www.w3.org/1999/xhtml" class="play-header">
            <h1><a href="plays/{$header/ancestor::tei:TEI/@xml:id}.html">{$titleStmt/tei:title/text()}</a></h1>
            <h2>By {$titleStmt/tei:author/text()}</h2>
            <ul>
            {
                for $resp in $titleStmt/tei:respStmt
                return
                    <li>{$resp/tei:resp/text()}: {$resp/tei:name/text()}</li>
            }
            </ul>
            { tei2:tei2html($pubStmt/*, $target-layer, $target-format) }
        </div>
};
