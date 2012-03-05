module namespace tei2="http://exist-db.org/xquery/app/tei2html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function tei2:tei2html($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:TEI) return
                tei2:tei2html($node/*)
            case element(tei:teiHeader) return
                tei2:header($node)
            case element(tei:text) return
                <div class="body">{ tei2:tei2html($node//tei:body) }</div>
            case element(tei:div) return
                let $level := count($node/ancestor-or-self::tei:div)
                let $type := if ($level eq 2) then "scene" else "act"
                return
                    <div id="{$node/@xml:id}" class="{$type}">
                        <a name="{$node/@xml:id}"></a>
                        { tei2:tei2html($node/node()) }
                    </div>
            case element(tei:head) return
                let $level := count($node/ancestor-or-self::tei:div)
                return
                    element { concat("h", $level) } {
                        tei2:tei2html($node/node())
                    }
            case element(tei:stage) return
                if ($node/ancestor::tei:l) then
                    <span class="stage">{ tei2:tei2html($node/node()) }</span>
                else
                    <p class="stage">{ tei2:tei2html($node/node()) }</p>
            case element(tei:sp) return
                if ($node/tei:l) then
                    <div class="sp">{ tei2:tei2html($node/node()) }</div>
                else
                    <div class="sp">
                        { tei2:tei2html($node/tei:speaker) }
                        <p class="p-ab">{ tei2:tei2html($node/tei:ab) }</p>
                    </div>
            case element(tei:l) return
                <p class="line">{ tei2:tei2html($node/node()) }</p>
            case element(tei:ab) return 
                <span class="ab">{ tei2:tei2html($node/node()) }</span>
            case element(tei:speaker) return
                <h5 class="speaker">{ tei2:tei2html($node/node()) }</h5>
            case element(tei:publicationStmt) return
                <div class="publicationStmt">{ tei2:tei2html($node/node()) }</div>
            case element(tei:sourceDesc) return
                <div class="sourceDesc">{ tei2:tei2html($node/node()) }</div>
            case element(tei:p) return 
                <p>{ tei2:tei2html($node/node()) }</p>
            case element(tei:title) return
                <em>{ tei2:tei2html($node/node()) }</em>
            case element() return
                tei2:tei2html($node/node())
            default return
                $node
};

declare function tei2:header($header as element(tei:teiHeader)) {
    let $titleStmt := $header//tei:titleStmt
    let $pubStmt := $header//tei:publicationStmt
    return
        <div class="play-header">
            <h1><a href="plays/{$header/ancestor::tei:TEI/@xml:id}.html">{$titleStmt/tei:title/text()}</a></h1>
            <h2>By {$titleStmt/tei:author/text()}</h2>
            <ul>
            {
                for $resp in $titleStmt/tei:respStmt
                return
                    <li>{$resp/tei:resp/text()}: {$resp/tei:name/text()}</li>
            }
            </ul>
            { tei2:tei2html($pubStmt/*) }
        </div>
};