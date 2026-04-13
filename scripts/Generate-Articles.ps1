Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Remove-Diacritics {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()

    foreach ($character in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($character) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void] $builder.Append($character)
        }
    }

    return $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
}

function ConvertTo-SlugPart {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $ascii = Remove-Diacritics $Value
    $lower = $ascii.ToLowerInvariant()
    $lower = $lower -replace "'", ""
    $lower = $lower -replace "[^a-z0-9]+", "-"
    $lower = $lower -replace "-{2,}", "-"

    return $lower.Trim("-")
}

function ConvertTo-PascalCase {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $parts = (ConvertTo-SlugPart $Value).Split("-", [System.StringSplitOptions]::RemoveEmptyEntries)
    $converted = foreach ($part in $parts) {
        if ($part.Length -eq 1) {
            $part.ToUpperInvariant()
        }
        else {
            $part.Substring(0, 1).ToUpperInvariant() + $part.Substring(1)
        }
    }

    return ($converted -join "")
}

function Escape-ForRazorHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return [System.Net.WebUtility]::HtmlEncode($Value).Replace("@", "@@")
}

function Apply-InlineMarkup {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $formatted = $Value
    $formatted = [regex]::Replace($formatted, "\*\*(.+?)\*\*", "<strong>`$1</strong>")
    $formatted = [regex]::Replace($formatted, "(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)", "<em>`$1</em>")
    $formatted = [regex]::Replace($formatted, "(?<!_)_(?!\s)(.+?)(?<!\s)_(?!_)", "<em>`$1</em>")

    return $formatted
}

function Convert-InlineMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $escaped = Escape-ForRazorHtml $Value

    $withLinks = [regex]::Replace(
        $escaped,
        "\[([^\]]+)\]\(([^)]+)\)",
        {
            param($match)

            $linkText = Apply-InlineMarkup (Escape-ForRazorHtml $match.Groups[1].Value)
            $href = [System.Net.WebUtility]::HtmlEncode($match.Groups[2].Value).Replace('"', "&quot;").Replace("@", "@@")

            return "<a href=""$href"" target=""_blank"" rel=""noreferrer"">$linkText</a>"
        }
    )

    return Apply-InlineMarkup $withLinks
}

function Test-IsMarkdownBlockStart {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Line
    )

    return $Line -match "^(#{1,3})\s+" -or
        $Line -match "^\s*>\s?" -or
        $Line -match "^\s*[-*]\s+" -or
        $Line -match "^\s*\d+\.\s+"
}

function Convert-MarkdownToHtmlLines {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Markdown
    )

    $lines = ($Markdown -replace "`r`n", "`n" -replace "`r", "`n").Split("`n")
    $output = [System.Collections.Generic.List[string]]::new()
    $index = 0
    $headingMap = @{
        1 = "h3"
        2 = "h4"
        3 = "h5"
    }

    while ($index -lt $lines.Length) {
        $line = $lines[$index].TrimEnd()

        if ([string]::IsNullOrWhiteSpace($line)) {
            $index++
            continue
        }

        if ($line -match "^(#{1,3})\s+(.+)$") {
            $tag = $headingMap[$matches[1].Length]
            $output.Add("        <$tag>$(Convert-InlineMarkdown $matches[2].Trim())</$tag>")
            $index++
            continue
        }

        if ($line -match "^\s*>\s?(.*)$") {
            $quoteLines = [System.Collections.Generic.List[string]]::new()

            while ($index -lt $lines.Length -and $lines[$index].TrimEnd() -match "^\s*>\s?(.*)$") {
                $quoteLines.Add($matches[1].Trim())
                $index++
            }

            $quoteText = ($quoteLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " "
            if (-not [string]::IsNullOrWhiteSpace($quoteText)) {
                $output.Add("        <blockquote><p>$(Convert-InlineMarkdown $quoteText)</p></blockquote>")
            }

            continue
        }

        if ($line -match "^\s*[-*]\s+(.+)$") {
            $items = [System.Collections.Generic.List[string]]::new()

            while ($index -lt $lines.Length -and $lines[$index].TrimEnd() -match "^\s*[-*]\s+(.+)$") {
                $items.Add("            <li>$(Convert-InlineMarkdown $matches[1].Trim())</li>")
                $index++
            }

            $output.Add("        <ul>")
            foreach ($item in $items) {
                $output.Add($item)
            }
            $output.Add("        </ul>")
            continue
        }

        if ($line -match "^\s*\d+\.\s+(.+)$") {
            $items = [System.Collections.Generic.List[string]]::new()

            while ($index -lt $lines.Length -and $lines[$index].TrimEnd() -match "^\s*\d+\.\s+(.+)$") {
                $items.Add("            <li>$(Convert-InlineMarkdown $matches[1].Trim())</li>")
                $index++
            }

            $output.Add("        <ol>")
            foreach ($item in $items) {
                $output.Add($item)
            }
            $output.Add("        </ol>")
            continue
        }

        $paragraphLines = [System.Collections.Generic.List[string]]::new()
        while ($index -lt $lines.Length) {
            $candidate = $lines[$index].Trim()
            if ([string]::IsNullOrWhiteSpace($candidate) -or (Test-IsMarkdownBlockStart $candidate)) {
                break
            }

            $paragraphLines.Add($candidate)
            $index++
        }

        if ($paragraphLines.Count -gt 0) {
            $output.Add("        <p>$(Convert-InlineMarkdown (($paragraphLines -join " ").Trim()))</p>")
            continue
        }

        $index++
    }

    return $output
}

function Parse-FrontMatter {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Lines,

        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    $values = @{}

    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -notmatch "^(?<key>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?<value>.*)$") {
            throw "Front matter invalide dans '$SourcePath' : '$line'"
        }

        $key = $matches["key"]
        $valueText = $matches["value"].Trim()

        if (($valueText.StartsWith('"') -and $valueText.EndsWith('"')) -or ($valueText.StartsWith("'") -and $valueText.EndsWith("'"))) {
            $value = $valueText.Substring(1, $valueText.Length - 2)
        }
        elseif ($valueText -match "^(true|false)$") {
            $value = $valueText -eq "true"
        }
        elseif ($valueText -match "^-?\d+$") {
            $value = [int] $valueText
        }
        else {
            $value = $valueText
        }

        $values[$key] = $value
    }

    return $values
}

function Parse-WritingMonth {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value,

        [Parameter(Mandatory = $true)]
        [string] $SourcePath
    )

    if ($Value -notmatch "^(?<month>[^\d]+?)\s+(?<year>\d{4})$") {
        throw "Le champ writing_month du fichier '$SourcePath' doit être au format 'Avril 2025'."
    }

    $monthName = (Remove-Diacritics $matches["month"]).Trim().ToLowerInvariant()
    $year = [int] $matches["year"]
    $monthMap = @{
        "janvier" = 1
        "fevrier" = 2
        "mars" = 3
        "avril" = 4
        "mai" = 5
        "juin" = 6
        "juillet" = 7
        "aout" = 8
        "septembre" = 9
        "octobre" = 10
        "novembre" = 11
        "decembre" = 12
    }

    if (-not $monthMap.ContainsKey($monthName)) {
        throw "Le mois '$($matches["month"])' du fichier '$SourcePath' n'est pas reconnu."
    }

    return [pscustomobject]@{
        Year = $year
        Month = $monthMap[$monthName]
    }
}

function Read-Article {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $File
    )

    $rawContent = Get-Content -Path $File.FullName -Raw -Encoding UTF8
    $normalized = $rawContent -replace "`r`n", "`n" -replace "`r", "`n"

    if (-not $normalized.StartsWith("---`n")) {
        throw "Le fichier '$($File.FullName)' doit commencer par un front matter YAML."
    }

    $closingIndex = $normalized.IndexOf("`n---`n", 4)
    if ($closingIndex -lt 0) {
        throw "Le front matter YAML du fichier '$($File.FullName)' n'est pas correctement fermé."
    }

    $frontMatterText = $normalized.Substring(4, $closingIndex - 4)
    $markdown = $normalized.Substring($closingIndex + 5).Trim()
    $metadata = Parse-FrontMatter -Lines ($frontMatterText.Split("`n")) -SourcePath $File.FullName

    foreach ($requiredField in @("title", "writing_month")) {
        if (-not $metadata.ContainsKey($requiredField) -or [string]::IsNullOrWhiteSpace([string] $metadata[$requiredField])) {
            throw "Le champ '$requiredField' est obligatoire dans '$($File.FullName)'."
        }
    }

    $writingMonth = Parse-WritingMonth -Value ([string] $metadata["writing_month"]) -SourcePath $File.FullName
    $published = if ($metadata.ContainsKey("published")) { [bool] $metadata["published"] } else { $false }
    $listed = if ($metadata.ContainsKey("listed")) { [bool] $metadata["listed"] } else { $false }
    $signature = if ($metadata.ContainsKey("signature") -and -not [string]::IsNullOrWhiteSpace([string] $metadata["signature"])) { [string] $metadata["signature"] } else { "Juste un homme" }
    $series = if ($metadata.ContainsKey("series") -and -not [string]::IsNullOrWhiteSpace([string] $metadata["series"])) { [string] $metadata["series"] } else { $null }
    $part = if ($metadata.ContainsKey("part")) { [int] $metadata["part"] } else { $null }
    $title = [string] $metadata["title"]
    $slug = "{0:D4}-{1:D2}-{2}" -f $writingMonth.Year, $writingMonth.Month, (ConvertTo-SlugPart $title)
    $componentName = "GeneratedArticle_{0}" -f (ConvertTo-PascalCase $slug)

    return [pscustomobject]@{
        SourcePath = $File.FullName
        RelativeSourcePath = [System.IO.Path]::GetRelativePath($script:RepoRoot, $File.FullName)
        Title = $title
        WritingMonth = [string] $metadata["writing_month"]
        Published = $published
        Listed = $listed
        Signature = $signature
        Series = $series
        Part = $part
        Slug = $slug
        ComponentName = $componentName
        FileName = "$componentName.razor"
        Markdown = $markdown
        HtmlLines = Convert-MarkdownToHtmlLines $markdown
        SortKey = [datetime]::new($writingMonth.Year, $writingMonth.Month, 1)
    }
}

function Get-SeriesMarkup {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $Article,

        [Parameter(Mandatory = $true)]
        [hashtable] $SeriesLookup
    )

    if ([string]::IsNullOrWhiteSpace($Article.Series) -or -not $SeriesLookup.ContainsKey($Article.Series)) {
        return [string[]] @()
    }

    $seriesArticles = @($SeriesLookup[$Article.Series])
    if ($seriesArticles.Length -eq 0) {
        return [string[]] @()
    }

    $currentIndex = -1
    for ($seriesIndex = 0; $seriesIndex -lt $seriesArticles.Length; $seriesIndex++) {
        if ($seriesArticles[$seriesIndex].Slug -eq $Article.Slug) {
            $currentIndex = $seriesIndex
            break
        }
    }

    if ($currentIndex -lt 0) {
        return [string[]] @()
    }

    $markup = [System.Collections.Generic.List[string]]::new()
    $markup.Add("        <div class=""journal-series"">")
    $markup.Add("            <p class=""series-label"">Suite : $(Escape-ForRazorHtml $Article.Series)</p>")
    $markup.Add("            <div class=""series-nav"">")

    if ($currentIndex -gt 0) {
        $previous = $seriesArticles[$currentIndex - 1]
        $markup.Add("                <a class=""series-link"" href=""/$($previous.Slug)"">&#8592; Partie precedente</a>")
    }
    else {
        $markup.Add("                <span class=""series-link disabled"">&#8592; Partie precedente</span>")
    }

    if ($currentIndex -lt ($seriesArticles.Length - 1)) {
        $next = $seriesArticles[$currentIndex + 1]
        $markup.Add("                <a class=""series-link"" href=""/$($next.Slug)"">Partie suivante &#8594;</a>")
    }
    else {
        $markup.Add("                <span class=""series-link disabled"">Partie suivante &#8594;</span>")
    }

    $markup.Add("            </div>")
    $markup.Add("            <ol class=""series-list"">")

    foreach ($seriesArticle in $seriesArticles) {
        $partLabel = if ($null -ne $seriesArticle.Part) { "Partie $($seriesArticle.Part) — " } else { "" }
        if ($seriesArticle.Slug -eq $Article.Slug) {
            $markup.Add("                <li class=""current"">$partLabel$(Escape-ForRazorHtml $seriesArticle.Title)</li>")
        }
        else {
            $markup.Add("                <li><a href=""/$($seriesArticle.Slug)"">$partLabel$(Escape-ForRazorHtml $seriesArticle.Title)</a></li>")
        }
    }

    $markup.Add("            </ol>")
    $markup.Add("        </div>")

    return [string[]] $markup.ToArray()
}

function Write-ArticlePages {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]] $PublishedArticles,

        [Parameter(Mandatory = $true)]
        [hashtable] $SeriesLookup
    )

    $pagesRoot = Join-Path $script:RepoRoot "Pages\Articles"
    New-Item -Path $pagesRoot -ItemType Directory -Force | Out-Null

    Get-ChildItem -Path $pagesRoot -Filter "GeneratedArticle_*.razor" -File -ErrorAction SilentlyContinue | Remove-Item -Force

    foreach ($article in $PublishedArticles) {
        $seriesMarkup = @(Get-SeriesMarkup -Article $article -SeriesLookup $SeriesLookup)
        $pageLines = [System.Collections.Generic.List[string]]::new()
        $pageLines.Add("@page ""/$($article.Slug)""")
        $pageLines.Add("")
        $pageLines.Add("<PageTitle>$(Escape-ForRazorHtml $article.Title) — La Vie d'un Homme</PageTitle>")
        $pageLines.Add("")
        $pageLines.Add("<div class=""journal-cover"">")
        $pageLines.Add("    <h1>La Vie d'un Homme</h1>")
        $pageLines.Add("    <p class=""subtitle"">Un journal intime numerique — emotions, anecdotes et fragments du quotidien.</p>")
        $pageLines.Add("</div>")
        $pageLines.Add("")
        $pageLines.Add("<div class=""journal-entry"">")
        $pageLines.Add("    <p class=""entry-date"">$(Escape-ForRazorHtml $article.WritingMonth)</p>")
        $pageLines.Add("    <h2>$(Escape-ForRazorHtml $article.Title)</h2>")

        foreach ($htmlLine in $article.HtmlLines) {
            $pageLines.Add($htmlLine)
        }

        if ($seriesMarkup.Length -gt 0) {
            $pageLines.Add("")
            foreach ($line in $seriesMarkup) {
                $pageLines.Add($line)
            }
        }

        $pageLines.Add("")
        $pageLines.Add("    <p class=""entry-signature"">— $(Escape-ForRazorHtml $article.Signature)</p>")
        $pageLines.Add("</div>")
        $pageLines.Add("")

        $destinationPath = Join-Path $pagesRoot $article.FileName
        Set-Content -Path $destinationPath -Value ($pageLines -join "`n") -Encoding UTF8
    }
}

function Update-NavMenu {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]] $ListedArticles
    )

    $navMenuPath = Join-Path $script:RepoRoot "Layout\NavMenu.razor"
    $startMarker = "        @* GENERATED ARTICLES START *@"
    $endMarker = "        @* GENERATED ARTICLES END *@"

    $generatedLines = [System.Collections.Generic.List[string]]::new()
    $generatedLines.Add($startMarker)

    foreach ($article in $ListedArticles) {
        $generatedLines.Add("        <div class=""nav-item px-3"">")
        $generatedLines.Add("            <NavLink class=""nav-link"" href=""$($article.Slug)"">")
        $generatedLines.Add("                <span class=""bi bi-journal-text-nav-menu"" aria-hidden=""true""></span> $(Escape-ForRazorHtml $article.Title)")
        $generatedLines.Add("            </NavLink>")
        $generatedLines.Add("        </div>")
    }

    $generatedLines.Add($endMarker)
    $generatedBlock = $generatedLines -join "`n"
    $navMenuContent = Get-Content -Path $navMenuPath -Raw -Encoding UTF8

    $updated = if ($navMenuContent.Contains($startMarker) -and $navMenuContent.Contains($endMarker)) {
        [regex]::Replace(
            $navMenuContent,
            [regex]::Escape($startMarker) + "(?s).*?" + [regex]::Escape($endMarker),
            [System.Text.RegularExpressions.MatchEvaluator] { param($match) $generatedBlock }
        )
    }
    else {
        $navMenuContent -replace "\s*</nav>", "`n$generatedBlock`n    </nav>"
    }

    Set-Content -Path $navMenuPath -Value $updated -Encoding UTF8
}

$script:RepoRoot = Split-Path -Path $PSScriptRoot -Parent
$contentRoot = Join-Path $script:RepoRoot "content\articles"

if (-not (Test-Path -Path $contentRoot)) {
    throw "Le dossier '$contentRoot' est introuvable."
}

$articleFiles = Get-ChildItem -Path $contentRoot -Recurse -File -Filter "*.md" |
    Where-Object {
        $_.BaseName -notlike "_*" -and
        $_.FullName -notmatch "[\\/](?:_[^\\/]+)[\\/]"
    }

$articles = [System.Collections.Generic.List[object]]::new()
foreach ($articleFile in $articleFiles) {
    $articles.Add((Read-Article -File $articleFile))
}

$groupedBySlug = $articles | Group-Object -Property Slug
foreach ($group in $groupedBySlug) {
    if ($group.Count -le 1) {
        continue
    }

    $orderedDuplicates = $group.Group | Sort-Object -Property RelativeSourcePath
    for ($duplicateIndex = 0; $duplicateIndex -lt $orderedDuplicates.Count; $duplicateIndex++) {
        if ($duplicateIndex -eq 0) {
            continue
        }

        $updatedSlug = "{0}-{1}" -f $orderedDuplicates[$duplicateIndex].Slug, ($duplicateIndex + 1)
        $orderedDuplicates[$duplicateIndex].Slug = $updatedSlug
        $orderedDuplicates[$duplicateIndex].ComponentName = "GeneratedArticle_{0}" -f (ConvertTo-PascalCase $updatedSlug)
        $orderedDuplicates[$duplicateIndex].FileName = "$($orderedDuplicates[$duplicateIndex].ComponentName).razor"
    }
}

$publishedArticles = [System.Collections.Generic.List[object]]::new()
foreach ($article in ($articles | Sort-Object -Property @{ Expression = { $_.SortKey }; Descending = $true }, @{ Expression = { $_.Title } })) {
    if ($article.Published) {
        $publishedArticles.Add($article)
    }
}

$seriesLookup = @{}
foreach ($article in $publishedArticles) {
    if ([string]::IsNullOrWhiteSpace($article.Series)) {
        continue
    }

    if (-not $seriesLookup.ContainsKey($article.Series)) {
        $seriesLookup[$article.Series] = [System.Collections.Generic.List[object]]::new()
    }

    $seriesLookup[$article.Series].Add($article)
}

foreach ($seriesName in $seriesLookup.Keys) {
    $sortedSeries = $seriesLookup[$seriesName] |
        Sort-Object -Property @{ Expression = { if ($null -ne $_.Part) { $_.Part } else { [int]::MaxValue } } }, @{ Expression = { $_.SortKey } }, @{ Expression = { $_.Title } }
    $seriesLookup[$seriesName] = [System.Collections.Generic.List[object]]::new()
    foreach ($article in $sortedSeries) {
        $seriesLookup[$seriesName].Add($article)
    }
}

$listedArticles = [System.Collections.Generic.List[object]]::new()
foreach ($article in $publishedArticles) {
    if ($article.Listed) {
        $listedArticles.Add($article)
    }
}

Write-ArticlePages -PublishedArticles $publishedArticles -SeriesLookup $seriesLookup
Update-NavMenu -ListedArticles $listedArticles
