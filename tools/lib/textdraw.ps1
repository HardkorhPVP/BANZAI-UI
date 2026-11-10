# BANZAI offline previews (tools/splitcheck.js): draws the text layer of a preview
# with the real Banzai fonts (JiberishMedia's Rubik-Bold / GasoekOne, 1.3.1 the
# Want Coffee display font, all from dist/) over the pixels splitcheck.js
# rendered. Not used in the game.
#   pwsh -File textdraw.ps1 <scene.json>
# scene: { base, out, fonts: { small, display, previous }, ops: [ { text, font, size, x, y, anchor, colors: [[r,g,b]...] | color, alpha, outline, shadow, clip: [x0,y0,x1,y1] } ] }
param([string]$scene)
Add-Type -AssemblyName System.Drawing
$s = Get-Content -Raw -Path $scene | ConvertFrom-Json
# one collection per file, so each font name maps to the family of its own file
$collections = @()
function Family($file) {
	if (-not $file) { return $null }
	$c = New-Object System.Drawing.Text.PrivateFontCollection
	$c.AddFontFile($file)
	$script:collections += $c
	return $c.Families[0]
}
$small = Family $s.fonts.small
$display = Family $s.fonts.display
$previous = Family $s.fonts.previous
if (-not $previous) { $previous = $display }
$img = [System.Drawing.Bitmap]::FromFile($s.base)
$bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($img, 0, 0, $img.Width, $img.Height)
$img.Dispose()
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$fmt = [System.Drawing.StringFormat]::GenericTypographic
$fmt.FormatFlags = $fmt.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces
function Col($c, $a) { [System.Drawing.Color]::FromArgb([int]([Math]::Max(0, [Math]::Min(255, $a * 255))), [int]($c[0] * 255), [int]($c[1] * 255), [int]($c[2] * 255)) }
foreach ($op in $s.ops) {
	$fam = if ($op.font -eq 'display') { $display } elseif ($op.font -eq 'previous') { $previous } else { $small }
	$em = [single]$op.size
	$text = [string]$op.text
	if ($text.Length -eq 0) { continue }
	$font = New-Object System.Drawing.Font($fam, $em, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
	# advance of each character (per-letter gradients) and the total width
	$adv = @()
	$total = 0.0
	for ($i = 0; $i -lt $text.Length; $i++) {
		$w = $g.MeasureString($text.Substring($i, 1), $font, (New-Object System.Drawing.PointF 0, 0), $fmt).Width
		if ($text[$i] -eq ' ') { $w = $em * 0.28 }
		$adv += $w
		$total += $w
	}
	$h = $em * 1.0
	$x = [single]$op.x; $y = [single]$op.y
	$a = [string]$op.anchor
	if ($a -match 'RIGHT') { $x0 = $x - $total } elseif ($a -match 'LEFT') { $x0 = $x } else { $x0 = $x - $total / 2 }
	if ($a -match '^TOP') { $y0 = $y } elseif ($a -match '^BOTTOM') { $y0 = $y - $h } else { $y0 = $y - $h / 2 }
	$y0 = $y0 - $em * 0.08
	$state = $g.Save()
	if ($op.clip) { $c = $op.clip; $g.SetClip((New-Object System.Drawing.RectangleF ([single]$c[0]), ([single]$c[1]), ([single]($c[2] - $c[0])), ([single]($c[3] - $c[1])))) }
	$alpha = if ($null -ne $op.alpha) { [double]$op.alpha } else { 1.0 }
	$cx = $x0
	for ($i = 0; $i -lt $text.Length; $i++) {
		$ch = $text.Substring($i, 1)
		$color = if ($op.colors) { $op.colors[[Math]::Min($i, $op.colors.Count - 1)] } else { $op.color }
		$path = New-Object System.Drawing.Drawing2D.GraphicsPath
		$path.AddString($ch, $fam, 0, $em, (New-Object System.Drawing.PointF ([single]$cx), ([single]$y0)), $fmt)
		if ($op.shadow) {
			$m = New-Object System.Drawing.Drawing2D.Matrix
			$m.Translate(1.3, 1.3)
			$sp = $path.Clone(); $sp.Transform($m)
			$g.FillPath((New-Object System.Drawing.SolidBrush (Col @(0, 0, 0) ($alpha * 0.9))), $sp)
		}
		if ($op.outline) {
			$pen = New-Object System.Drawing.Pen (Col @(0, 0, 0) ($alpha * 0.95)), 2.2
			$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
			$g.DrawPath($pen, $path)
		}
		$g.FillPath((New-Object System.Drawing.SolidBrush (Col $color $alpha)), $path)
		$cx += $adv[$i]
	}
	$g.Restore($state)
	$font.Dispose()
}
$bmp.Save($s.out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
