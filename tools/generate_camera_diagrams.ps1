Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-FontSafe {
    param(
        [string]$Primary,
        [float]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    try {
        return New-Object System.Drawing.Font($Primary, $Size, $Style)
    }
    catch {
        return New-Object System.Drawing.Font('Arial', $Size, $Style)
    }
}

function New-Canvas {
    param(
        [int]$Width,
        [int]$Height,
        [string]$Title,
        [string]$Subtitle
    )

    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.Clear([System.Drawing.Color]::FromArgb(248, 249, 252))

    $titleFont = New-FontSafe 'Microsoft YaHei' 28 ([System.Drawing.FontStyle]::Bold)
    $subFont = New-FontSafe 'Microsoft YaHei' 12 ([System.Drawing.FontStyle]::Regular)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(31, 41, 55))
    $subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(75, 85, 99))

    $g.DrawString($Title, $titleFont, $titleBrush, 40, 24)
    $g.DrawString($Subtitle, $subFont, $subBrush, 42, 68)
    $g.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(209, 213, 219), 2)), 40, 102, ($Width - 40), 102)

    return @{
        Bitmap = $bmp
        Graphics = $g
    }
}

function New-Brush {
    param([int]$R, [int]$G, [int]$B, [int]$A = 255)
    return New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($A, $R, $G, $B))
}

function New-Pen {
    param(
        [int]$R,
        [int]$G,
        [int]$B,
        [float]$Width = 2.0,
        [int]$A = 255
    )
    return New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($A, $R, $G, $B), $Width)
}

function Draw-RoundedRect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius,
        [System.Drawing.Brush]$Brush,
        [System.Drawing.Pen]$Pen
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $Graphics.FillPath($Brush, $path)
    $Graphics.DrawPath($Pen, $path)
    $path.Dispose()
}

function Draw-Panel {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Title,
        [string[]]$Lines,
        [string]$Theme = 'gray'
    )

    switch ($Theme) {
        'blue' {
            $FillColor = [System.Drawing.Color]::FromArgb(239, 246, 255)
            $BorderColor = [System.Drawing.Color]::FromArgb(59, 130, 246)
        }
        'green' {
            $FillColor = [System.Drawing.Color]::FromArgb(240, 253, 250)
            $BorderColor = [System.Drawing.Color]::FromArgb(16, 185, 129)
        }
        'orange' {
            $FillColor = [System.Drawing.Color]::FromArgb(255, 247, 237)
            $BorderColor = [System.Drawing.Color]::FromArgb(249, 115, 22)
        }
        'red' {
            $FillColor = [System.Drawing.Color]::FromArgb(254, 242, 242)
            $BorderColor = [System.Drawing.Color]::FromArgb(239, 68, 68)
        }
        'purple' {
            $FillColor = [System.Drawing.Color]::FromArgb(245, 243, 255)
            $BorderColor = [System.Drawing.Color]::FromArgb(139, 92, 246)
        }
        'teal' {
            $FillColor = [System.Drawing.Color]::FromArgb(240, 253, 250)
            $BorderColor = [System.Drawing.Color]::FromArgb(20, 184, 166)
        }
        'gray' {
            $FillColor = [System.Drawing.Color]::FromArgb(243, 244, 246)
            $BorderColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
        }
        default {
            $FillColor = [System.Drawing.Color]::FromArgb(243, 244, 246)
            $BorderColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
        }
    }

    $fillBrush = New-Object System.Drawing.SolidBrush($FillColor)
    $pen = New-Object System.Drawing.Pen($BorderColor, 2.0)
    Draw-RoundedRect -Graphics $Graphics -X $X -Y $Y -Width $Width -Height $Height -Radius 18 -Brush $fillBrush -Pen $pen

    $titleFont = New-FontSafe 'Microsoft YaHei' 15 ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-FontSafe 'Microsoft YaHei' 11 ([System.Drawing.FontStyle]::Regular)
    $titleBrush = New-Brush 17 24 39
    $bodyBrush = New-Brush 55 65 81

    $Graphics.DrawString($Title, $titleFont, $titleBrush, ($X + 16), ($Y + 12))
    $lineY = $Y + 42
    foreach ($line in $Lines) {
        $Graphics.DrawString("• $line", $bodyFont, $bodyBrush, ($X + 16), $lineY)
        $lineY += 22
    }

    $fillBrush.Dispose()
    $pen.Dispose()
    $titleFont.Dispose()
    $bodyFont.Dispose()
    $titleBrush.Dispose()
    $bodyBrush.Dispose()
}

function Draw-FlowBox {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Text,
        [System.Drawing.Color]$FillColor
    )

    $fillBrush = New-Object System.Drawing.SolidBrush($FillColor)
    $pen = New-Pen 99 102 241 2
    Draw-RoundedRect -Graphics $Graphics -X $X -Y $Y -Width $Width -Height $Height -Radius 16 -Brush $fillBrush -Pen $pen

    $font = New-FontSafe 'Microsoft YaHei' 12 ([System.Drawing.FontStyle]::Bold)
    $brush = New-Brush 17 24 39
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)
    $Graphics.DrawString($Text, $font, $brush, $rect, $format)

    $fillBrush.Dispose()
    $pen.Dispose()
    $font.Dispose()
    $brush.Dispose()
    $format.Dispose()
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X1,
        [float]$Y1,
        [float]$X2,
        [float]$Y2,
        [System.Drawing.Color]$Color
    )

    $pen = New-Object System.Drawing.Pen($Color, 3.0)
    $pen.CustomEndCap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap(6, 6, $true)
    $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    $pen.Dispose()
}

function Draw-SmallLabel {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [string]$Text,
        [System.Drawing.Color]$FillColor
    )

    $font = New-FontSafe 'Microsoft YaHei' 9 ([System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush($FillColor)
    $textBrush = New-Brush 255 255 255
    $size = $Graphics.MeasureString($Text, $font)
    $rectW = [math]::Ceiling($size.Width + 18)
    $rectH = [math]::Ceiling($size.Height + 8)
    $pen = New-Pen 0 0 0 0
    Draw-RoundedRect -Graphics $Graphics -X $X -Y $Y -Width $rectW -Height $rectH -Radius 12 -Brush $brush -Pen $pen
    $Graphics.DrawString($Text, $font, $textBrush, ($X + 9), ($Y + 4))
    $font.Dispose()
    $brush.Dispose()
    $textBrush.Dispose()
    $pen.Dispose()
}

function Draw-ChartAxes {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$XLabel,
        [string]$YLabel
    )

    $axisPen = New-Pen 71 85 105 2.5
    $gridPen = New-Pen 203 213 225 1
    for ($i = 1; $i -lt 5; $i++) {
        $Graphics.DrawLine($gridPen, $X, ($Y + $i * ($Height / 5)), ($X + $Width), ($Y + $i * ($Height / 5)))
        $Graphics.DrawLine($gridPen, ($X + $i * ($Width / 5)), $Y, ($X + $i * ($Width / 5)), ($Y + $Height))
    }
    $Graphics.DrawLine($axisPen, $X, ($Y + $Height), ($X + $Width), ($Y + $Height))
    $Graphics.DrawLine($axisPen, $X, ($Y + $Height), $X, $Y)
    Draw-Arrow -Graphics $Graphics -X1 ($X + $Width - 10) -Y1 ($Y + $Height) -X2 ($X + $Width + 20) -Y2 ($Y + $Height) -Color ([System.Drawing.Color]::FromArgb(71, 85, 105))
    Draw-Arrow -Graphics $Graphics -X1 $X -Y1 ($Y + 10) -X2 $X -Y2 ($Y - 20) -Color ([System.Drawing.Color]::FromArgb(71, 85, 105))
    $font = New-FontSafe 'Microsoft YaHei' 11 ([System.Drawing.FontStyle]::Bold)
    $brush = New-Brush 55 65 81
    $Graphics.DrawString($XLabel, $font, $brush, ($X + $Width - 80), ($Y + $Height + 12))
    $Graphics.DrawString($YLabel, $font, $brush, ($X - 6), ($Y - 28))
    $axisPen.Dispose()
    $gridPen.Dispose()
    $font.Dispose()
    $brush.Dispose()
}

function Draw-PolyLine {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.PointF[]]$Points,
        [System.Drawing.Color]$Color,
        [float]$Width = 3.0
    )
    $pen = New-Object System.Drawing.Pen($Color, $Width)
    $Graphics.DrawLines($pen, $Points)
    $pen.Dispose()
}

function Draw-TextBlock {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [string]$Text,
        [float]$FontSize = 11,
        [bool]$Bold = $false
    )

    $style = [System.Drawing.FontStyle]::Regular
    if ($Bold) {
        $style = [System.Drawing.FontStyle]::Bold
    }
    $font = New-FontSafe 'Microsoft YaHei' $FontSize $style
    $brush = New-Brush 55 65 81
    $rect = New-Object System.Drawing.RectangleF($X, $Y, $Width, 200)
    $Graphics.DrawString($Text, $font, $brush, $rect)
    $font.Dispose()
    $brush.Dispose()
}

function Save-Diagram {
    param(
        [hashtable]$Canvas,
        [string]$Path
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    $Canvas.Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Canvas.Graphics.Dispose()
    $Canvas.Bitmap.Dispose()
}

function Draw-AE-Pipeline {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AE Pipeline' '从 IFE 亮度统计到曝光回写 Sensor 的控制闭环'
    $g = $c.Graphics

    Draw-Panel $g 40 130 280 180 '输入信号' @('BG/BHIST 亮度统计', '人脸 ROI / 触摸 ROI', '模式: preview / video / snapshot', '约束: FPS / anti-banding / HDR') 'blue'
    Draw-Panel $g 1470 130 290 180 '输出结果' @('linecount / exposure time', 'analog gain / digital gain', 'frame length / FPS 边界', '下一帧 sensor register 更新') 'green'

    $boxes = @(
        @{X=360; Y=170; W=170; H=74; T='Stats Parser'; C=[System.Drawing.Color]::FromArgb(224,231,255)},
        @{X=560; Y=170; W=170; H=74; T='场景检测'; C=[System.Drawing.Color]::FromArgb(224,231,255)},
        @{X=760; Y=170; W=170; H=74; T='Target Y'; C=[System.Drawing.Color]::FromArgb(224,231,255)},
        @{X=960; Y=170; W=190; H=74; T='Exposure Solver'; C=[System.Drawing.Color]::FromArgb(224,231,255)},
        @{X=1180; Y=170; W=190; H=74; T='Temporal Smooth'; C=[System.Drawing.Color]::FromArgb(224,231,255)}
    )
    foreach ($b in $boxes) {
        Draw-FlowBox $g $b.X $b.Y $b.W $b.H $b.T $b.C
    }
    Draw-Arrow $g 321 207 360 207 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 530 207 560 207 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 730 207 760 207 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 930 207 960 207 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 1150 207 1180 207 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 1370 207 1470 207 ([System.Drawing.Color]::FromArgb(22,163,74))

    Draw-Panel $g 80 380 370 260 '场景分析重点' @('人脸场景: 提高 ROI 权重', '背光场景: 主体和背景折中', '低照场景: 容忍整体偏暗', '视频场景: 亮度稳定优先', '闪光灯场景: 预闪 / 主闪切换') 'orange'
    Draw-Panel $g 500 380 420 260 '求解器内部约束' @('先拉曝光时间，再拉模拟增益', 'linecount 受 frame length 和帧率限制', '防频闪要求快门落在安全点', '运动场景优先保证快门不太慢', 'HDR / MFNR 可能额外约束曝光组合') 'red'
    Draw-Panel $g 980 380 380 260 '平滑与收敛' @('避免一帧内亮度大幅跳变', '场景突变时允许快速收敛', '稳定场景减少来回抖动', '可配合 hysteresis 防止边界抖动') 'teal'
    Draw-Panel $g 1410 380 330 260 '调试时先看' @('avgY 与 targetY 的偏差', 'linecount 是否撞上下限', 'gain 是否过高', 'banding mode 是否正确', 'ROI / face weight 是否生效') 'purple'

    Draw-SmallLabel $g 520 690 '典型闭环' ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-FlowBox $g 300 740 220 72 'Sensor Capture' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 610 740 220 72 'IFE Stats' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 920 740 220 72 'AEC Decision' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 1230 740 220 72 'Apply Exposure' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-Arrow $g 520 776 610 776 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 830 776 920 776 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 1140 776 1230 776 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-Arrow $g 1340 814 410 870 ([System.Drawing.Color]::FromArgb(79,70,229))
    Draw-TextBlock $g 1420 725 320 '调试结论通常要同时回答三件事：`为什么亮度不对`、`被什么约束卡住`、以及 `是输入问题还是策略取舍`。' 12 $true

    Save-Diagram $c $Path
}

function Draw-AE-Banding {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AE Anti-Banding' '室内频闪场景下 50Hz / 60Hz 的快门安全点、症状和调试思路'
    $g = $c.Graphics

    Draw-Panel $g 40 130 300 180 '为什么会闪' @('市电驱动灯源亮度会周期变化', '快门如果不与周期对齐，帧间亮度会抖', 'LED / 荧光灯 / 商场灯带最常见') 'red'

    $baseX1 = 390
    $baseY = 190
    $axisPen = New-Pen 100 116 139 2
    $g.DrawString('50Hz 环境: 推荐快门 1/100s, 1/50s, 1/25s', (New-FontSafe 'Microsoft YaHei' 14 ([System.Drawing.FontStyle]::Bold)), (New-Brush 17 24 39), $baseX1, 130)
    $g.DrawLine($axisPen, $baseX1, $baseY, 840, $baseY)
    $pts50 = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    for ($i = 0; $i -le 320; $i++) {
        $x = $baseX1 + $i
        $y = $baseY - [math]::Sin(($i / 320.0) * 8 * [math]::PI) * 55
        $pts50.Add((New-Object System.Drawing.PointF([float]$x, [float]$y)))
    }
    Draw-PolyLine $g $pts50.ToArray() ([System.Drawing.Color]::FromArgb(59,130,246)) 3
    foreach ($x in @(440, 540, 640, 740)) {
        $pen = New-Pen 22 163 74 3
        $g.DrawLine($pen, $x, 115, $x, 265)
        $pen.Dispose()
    }
    Draw-Panel $g 360 300 520 220 '50Hz 现象' @('快门常落在 1/100s 或 1/50s 附近', '亮度不够时优先抬 gain 而不是随便改快门', '如果频繁在安全点之间跳，会看到轻微闪动') 'blue'

    $baseX2 = 980
    $g.DrawString('60Hz 环境: 推荐快门 1/120s, 1/60s, 1/30s', (New-FontSafe 'Microsoft YaHei' 14 ([System.Drawing.FontStyle]::Bold)), (New-Brush 17 24 39), $baseX2, 130)
    $g.DrawLine($axisPen, $baseX2, $baseY, 1440, $baseY)
    $pts60 = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    for ($i = 0; $i -le 320; $i++) {
        $x = $baseX2 + $i
        $y = $baseY - [math]::Sin(($i / 320.0) * 9.6 * [math]::PI) * 55
        $pts60.Add((New-Object System.Drawing.PointF([float]$x, [float]$y)))
    }
    Draw-PolyLine $g $pts60.ToArray() ([System.Drawing.Color]::FromArgb(139,92,246)) 3
    foreach ($x in @(1030, 1110, 1190, 1270, 1350)) {
        $pen = New-Pen 22 163 74 3
        $g.DrawLine($pen, $x, 115, $x, 265)
        $pen.Dispose()
    }
    Draw-Panel $g 950 300 520 220 '60Hz 现象' @('北美设备、部分屏闪环境更常见', '视频模式尤其依赖安全点稳定', '配置错误时容易表现为预览明暗起伏') 'purple'

    Draw-Panel $g 70 620 520 330 '定位步骤' @('先确认现场更像 50Hz 还是 60Hz', '再看 exposure time 是否落在安全点', '再看亮度不足时是不是被迫抬 gain', '最后确认 banding mode 是否和实际环境匹配', '某些现场会混合多种灯源，需要结合体验判断') 'green'
    Draw-Panel $g 650 620 520 330 '常见误判' @('把 tone mapping 引起的观感变化误判成频闪', '只看一帧快门，不看多帧变化', '忽略了 ROI / 人脸权重导致的目标亮度变化', '忽略视频模式和拍照模式的约束差异') 'orange'
    Draw-Panel $g 1230 620 500 330 '最终调试结论应包含' @('当前环境频率判断', '当前快门落点', '是否存在 banding-safe 约束', '是否因此造成增益升高 / 亮度不足', '建议是改策略、改配置，还是接受 trade-off') 'gray'

    $axisPen.Dispose()
    Save-Diagram $c $Path
}

function Draw-AE-Checklist {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AE Debug Checklist' '把亮度问题拆成偏暗 / 偏亮 / 闪烁 / 跳变四类来定位'
    $g = $c.Graphics

    Draw-Panel $g 60 150 780 360 '偏暗 / 噪声高' @('看 avgY 是否显著低于 targetY', '看 linecount 是否已撞上限', '看 analog / digital gain 是否过高', '看 ROI 是否被背景拖低', '看 night / motion / flicker 约束是否生效') 'blue'
    Draw-Panel $g 960 150 780 360 '偏亮 / 高光死白' @('看 targetY 是否配置偏高', '看 HDR 或背光策略是否缺失', '看高亮区域是否影响整体测光', '看人脸优先是否导致背景过亮', '看 AE 问题还是 tone mapping 问题') 'red'
    Draw-Panel $g 60 560 780 360 '闪烁 / 室内明暗摆动' @('看 banding mode 是否匹配 50/60Hz', '看 exposure time 是否落在安全点', '看多帧间快门是否频繁来回跳', '看灯源是否复杂且混合', '看视频模式下是否更明显') 'purple'
    Draw-Panel $g 960 560 780 360 '亮度跳变 / 场景切换不自然' @('看 temporal smooth 是否过弱', '看 ROI / face detect 是否突然变化', '看场景模式切换阈值', '看 lux index / exp index 是否抖动', '判断是策略边界问题还是统计异常') 'green'

    Draw-SmallLabel $g 760 475 '调试优先级' ([System.Drawing.Color]::FromArgb(37,99,235))
    Draw-FlowBox $g 650 475 160 60 '先看统计' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 830 475 160 60 '再看约束' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 1010 475 160 60 '最后看策略' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-Arrow $g 810 505 830 505 ([System.Drawing.Color]::FromArgb(37,99,235))
    Draw-Arrow $g 990 505 1010 505 ([System.Drawing.Color]::FromArgb(37,99,235))

    Save-Diagram $c $Path
}

function Draw-AE-LogExample {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AE Log Example' '通过多帧日志观察 avgY、targetY、linecount、gain 和 banding 的联动'
    $g = $c.Graphics

    Draw-Panel $g 40 130 430 180 '怎么看日志' @('不要只看单帧', '至少看 10~20 帧趋势', '把快门、增益、targetY 放在一起看', '同时关注 mode / ROI / banding') 'blue'

    $logBrush = New-Brush 17 24 39
    $monoFont = New-FontSafe 'Consolas' 14 ([System.Drawing.FontStyle]::Regular)
    $panelBrush = New-Brush 255 255 255
    $panelPen = New-Pen 148 163 184 2
    Draw-RoundedRect $g 40 340 980 650 18 $panelBrush $panelPen
    $g.DrawString('frame  avgY  targetY  linecount  gain  banding  note', (New-FontSafe 'Consolas' 15 ([System.Drawing.FontStyle]::Bold)), $logBrush, 70, 370)
    $rows = @(
        '118    39    58       760        2.0   50Hz     scene enters room',
        '119    42    58       820        2.1   50Hz     raise linecount first',
        '120    47    58       900        2.1   50Hz     still under target',
        '121    53    58       980        2.2   50Hz     close to stable',
        '122    57    58       1000       2.2   50Hz     converge',
        '123    58    58       1000       2.2   50Hz     stable',
        '124    56    58       1000       2.4   50Hz     face enters ROI',
        '125    58    58       1000       2.4   50Hz     new stable point'
    )
    $y = 420
    foreach ($row in $rows) {
        $g.DrawString($row, $monoFont, $logBrush, 70, $y)
        $y += 58
    }

    Draw-Panel $g 1070 180 670 260 '逐段解读' @('118-122: 主要通过 linecount 收敛', '122-123: 到达目标亮度后保持稳定', '124: ROI 变化导致 target 实际策略变化', '124-125: 由于 linecount 已到上限，改用 gain 微调') 'green'
    Draw-Panel $g 1070 490 670 240 '结论模板' @('当前是否存在 banding-safe 限制', '当前主要靠快门还是靠增益补亮', 'ROI / face 是否改变了结果', '亮度问题是无法收敛还是收敛到了不理想目标') 'orange'
    Draw-Panel $g 1070 770 670 200 '推荐记录字段' @('frame / avgY / targetY / linecount', 'analog gain / digital gain', 'banding mode / lux index / ROI', 'scene detect / face weight / mode') 'purple'

    $monoFont.Dispose()
    $logBrush.Dispose()
    $panelBrush.Dispose()
    $panelPen.Dispose()
    Save-Diagram $c $Path
}

function Draw-AF-StateMachine {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AF State Machine' '从 trigger 到 focused / tracking / failed 的典型状态流'
    $g = $c.Graphics

    $states = @(
        @{X=150; Y=220; W=190; H=78; T='Idle'},
        @{X=430; Y=220; W=210; H=78; T='Triggered'},
        @{X=730; Y=220; W=220; H=78; T='PD Check'},
        @{X=1060; Y=120; W=240; H=78; T='Coarse Search'},
        @{X=1060; Y=320; W=240; H=78; T='Fine Search'},
        @{X=1410; Y=220; W=200; H=78; T='Focused'},
        @{X=1410; Y=430; W=200; H=78; T='Tracking'},
        @{X=1060; Y=540; W=240; H=78; T='Failed'}
    )
    foreach ($s in $states) { Draw-FlowBox $g $s.X $s.Y $s.W $s.H $s.T ([System.Drawing.Color]::FromArgb(224,231,255)) }
    Draw-Arrow $g 340 259 430 259 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 640 259 730 259 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 950 245 1060 160 ([System.Drawing.Color]::FromArgb(249,115,22))
    Draw-Arrow $g 950 273 1060 359 ([System.Drawing.Color]::FromArgb(16,185,129))
    Draw-Arrow $g 1300 359 1410 259 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1510 298 1510 430 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1410 469 640 720 ([System.Drawing.Color]::FromArgb(99,102,241))
    Draw-Arrow $g 1180 398 1180 540 ([System.Drawing.Color]::FromArgb(239,68,68))
    Draw-Arrow $g 1060 579 340 259 ([System.Drawing.Color]::FromArgb(239,68,68))

    Draw-SmallLabel $g 450 170 'tap / shutter / CAF' ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-SmallLabel $g 930 120 'PDAF unavailable' ([System.Drawing.Color]::FromArgb(249,115,22))
    Draw-SmallLabel $g 930 400 'PDAF valid or near peak' ([System.Drawing.Color]::FromArgb(16,185,129))
    Draw-SmallLabel $g 1320 340 'FV stable' ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-SmallLabel $g 1210 640 'timeout / no peak' ([System.Drawing.Color]::FromArgb(239,68,68))

    Draw-Panel $g 80 760 500 250 '调试关注点' @('状态切换是否符合场景', '是不是反复 Triggered -> FineSearch', 'Failed 后是否能正确回 Idle', 'Tracking 是否过于敏感导致抽动') 'blue'
    Draw-Panel $g 650 760 500 250 '统计信号' @('PDAF confidence', 'Focus Value 曲线峰值', 'lens position / DAC', 'settle time 是否足够') 'green'
    Draw-Panel $g 1220 760 500 250 '常见异常' @('低照: PDAF 置信度不足', '白墙: FV 没有明显峰值', '运动场景: Tracking 频繁重触发', 'Actuator 问题: 位置走不到目标') 'red'

    Save-Diagram $c $Path
}

function Draw-AF-SearchCurve {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AF Search Curve' '用 Focus Value 曲线理解 coarse search、fine search 和 peak lock'
    $g = $c.Graphics

    Draw-ChartAxes $g 120 240 980 620 'Lens Position' 'Focus Value'
    $points = @(
        (New-Object System.Drawing.PointF(150, 800)),
        (New-Object System.Drawing.PointF(250, 760)),
        (New-Object System.Drawing.PointF(350, 670)),
        (New-Object System.Drawing.PointF(450, 540)),
        (New-Object System.Drawing.PointF(550, 430)),
        (New-Object System.Drawing.PointF(650, 350)),
        (New-Object System.Drawing.PointF(750, 310)),
        (New-Object System.Drawing.PointF(850, 360)),
        (New-Object System.Drawing.PointF(950, 520)),
        (New-Object System.Drawing.PointF(1050, 700))
    )
    Draw-PolyLine $g $points ([System.Drawing.Color]::FromArgb(37,99,235)) 4
    foreach ($pt in $points) {
        $g.FillEllipse((New-Brush 37 99 235), ($pt.X - 6), ($pt.Y - 6), 12, 12)
    }
    foreach ($pt in @($points[0], $points[2], $points[4], $points[6], $points[8])) {
        $g.DrawEllipse((New-Pen 249 115 22 4), ($pt.X - 10), ($pt.Y - 10), 20, 20)
    }
    foreach ($pt in @($points[5], $points[6], $points[7])) {
        $g.DrawEllipse((New-Pen 22 163 74 4), ($pt.X - 14), ($pt.Y - 14), 28, 28)
    }
    Draw-SmallLabel $g 230 860 'coarse samples' ([System.Drawing.Color]::FromArgb(249,115,22))
    Draw-SmallLabel $g 690 240 'fine search around peak' ([System.Drawing.Color]::FromArgb(22,163,74))
    Draw-SmallLabel $g 760 285 'peak lock' ([System.Drawing.Color]::FromArgb(37,99,235))

    Draw-Panel $g 1170 180 560 250 '图怎么读' @('横轴是镜头位置，纵轴是清晰度评价值', 'coarse search 用较大步长快速找峰值区间', 'fine search 在峰值附近缩小步进', '最终锁在峰值附近而不是简单走到尽头') 'blue'
    Draw-Panel $g 1170 470 560 250 '为什么会拉风箱' @('曲线过平: 不知道峰值在哪', '低照噪声大: FV 上下抖动', '步进过大: 错过峰值', 'settle time 不够: 评价值采样太早') 'red'
    Draw-Panel $g 1170 760 560 210 '调试建议' @('同时记录 lens position 与 FV', '观察 coarse -> fine 是否真的缩步进', '确认峰值附近是否连续多帧稳定') 'green'

    Save-Diagram $c $Path
}

function Draw-AF-PDAF {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AF PDAF Flow' 'PDAF 负责给方向和粗目标位，contrast 用来做最后确认'
    $g = $c.Graphics

    $boxes = @(
        @{X=100; Y=180; W=220; H=78; T='PDAF Raw Stats'},
        @{X=400; Y=180; W=220; H=78; T='Confidence Check'},
        @{X=700; Y=180; W=220; H=78; T='Direction + Defocus'},
        @{X=1000; Y=180; W=220; H=78; T='Move Lens'},
        @{X=1300; Y=180; W=220; H=78; T='FV Confirm'}
    )
    foreach ($b in $boxes) { Draw-FlowBox $g $b.X $b.Y $b.W $b.H $b.T ([System.Drawing.Color]::FromArgb(224,231,255)) }
    Draw-Arrow $g 320 219 400 219 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 620 219 700 219 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 920 219 1000 219 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1220 219 1300 219 ([System.Drawing.Color]::FromArgb(59,130,246))

    Draw-FlowBox $g 700 360 260 78 'Fallback: Contrast Sweep' ([System.Drawing.Color]::FromArgb(254,226,226))
    Draw-Arrow $g 510 258 830 360 ([System.Drawing.Color]::FromArgb(239,68,68))
    Draw-SmallLabel $g 430 285 'confidence low' ([System.Drawing.Color]::FromArgb(239,68,68))
    Draw-Arrow $g 960 399 1110 258 ([System.Drawing.Color]::FromArgb(239,68,68))

    Draw-Panel $g 60 530 520 290 'PDAF 真正解决的问题' @('告诉 AF 该往近焦还是远焦方向走', '减少全范围扫描带来的时间成本', '更适合连续跟焦和视频') 'blue'
    Draw-Panel $g 650 530 520 290 '什么时候不可靠' @('低照下信噪比不足', '纯色或低纹理场景', '逆光或奇异照明', '模组标定或像素映射有误差') 'red'
    Draw-Panel $g 1240 530 500 290 '为什么还要 FV Confirm' @('PDAF 负责快，但不一定最后最准', 'FV 或 contrast 可确认峰值位置', '混合 AF 兼顾速度和精度') 'green'
    Draw-Panel $g 350 860 1120 160 '高通平台看源码时，建议优先串这条线：PDAF stats parser -> confidence 判定 -> lens move -> FV confirm -> AF state machine。' @() 'purple'

    Save-Diagram $c $Path
}

function Draw-AF-FailCase {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AF Failure Cases' '把失焦问题拆成统计、状态机、执行器和场景四类'
    $g = $c.Graphics

    Draw-Panel $g 60 150 390 350 '低照失败' @('症状: 对焦慢、犹豫、反复确认', '看点: PDAF confidence / FV 抖动', '优先怀疑: 信噪比不足、settle 不够') 'red'
    Draw-Panel $g 490 150 390 350 '低纹理失败' @('症状: 白墙或纯色面很难锁定', '看点: FV 曲线过平', '优先怀疑: contrast 搜索无峰值') 'orange'
    Draw-Panel $g 920 150 390 350 '运动主体失败' @('症状: 视频抽焦、跟不上主体', '看点: Tracking 频繁重触发', '优先怀疑: 触发阈值过敏、速度估计不足') 'blue'
    Draw-Panel $g 1350 150 390 350 '执行器失败' @('症状: 目标位置对但图仍不清', '看点: lens position 是否真的走到', '优先怀疑: actuator、霍尔反馈、标定') 'purple'

    Draw-Panel $g 150 600 1500 320 '推荐定位顺序' @('先看状态机是否合理触发', '再看 PDAF / FV 是否提供了足够信息', '再看镜头是不是准确执行了目标位', '最后结合具体场景判断是策略问题还是硬件边界', '如果是视频问题，还要额外判断 CAF 重触发是否太敏感') 'green'

    Save-Diagram $c $Path
}

function Draw-AWB-Pipeline {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AWB Pipeline' '从 RGB/Bayer 统计到 CCT、Tint、RGB Gains 和 CCM 更新'
    $g = $c.Graphics

    Draw-Panel $g 40 130 280 190 '输入' @('RGB / Bayer stats', '人脸和肤色区域', '历史帧结果', '场景信息: indoor / outdoor / mixed') 'blue'
    Draw-Panel $g 1490 130 270 190 '输出' @('R/G/B gain', 'CCT', 'Tint', 'CCM 或 color pipeline 更新') 'green'

    $boxes = @(
        @{X=360; Y=180; W=190; H=72; T='Neutral Filter'},
        @{X=590; Y=180; W=190; H=72; T='Feature Extract'},
        @{X=820; Y=180; W=200; H=72; T='Light Classify'},
        @{X=1060; Y=180; W=200; H=72; T='Solve CCT/Tint'},
        @{X=1300; Y=180; W=160; H=72; T='Temporal Smooth'}
    )
    foreach ($b in $boxes) { Draw-FlowBox $g $b.X $b.Y $b.W $b.H $b.T ([System.Drawing.Color]::FromArgb(224,231,255)) }
    Draw-Arrow $g 321 216 360 216 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 550 216 590 216 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 780 216 820 216 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1020 216 1060 216 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1260 216 1300 216 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1460 216 1490 216 ([System.Drawing.Color]::FromArgb(22,163,74))

    Draw-Panel $g 80 390 380 260 'Neutral Filter 在做什么' @('剔除过曝和饱和色块', '避免强单色光源污染', '优先找接近中性色的候选区域') 'orange'
    Draw-Panel $g 500 390 380 260 'Light Source Classification' @('根据 R/G、B/G 落区判断', '常见区域: A / TL84 / D65 / Shade', '混光场景可能输出折中决策') 'blue'
    Draw-Panel $g 920 390 380 260 '稳定策略' @('不要每帧都大幅改 gain', '人脸场景优先保肤色', '混光场景优先稳定和观感') 'green'
    Draw-Panel $g 1340 390 390 260 '最终关注点' @('白色是否接近中性', '肤色是否自然', '同一场景是否忽冷忽暖', '是否需要同时回看 CCM / tone mapping') 'purple'

    Draw-Panel $g 240 730 1320 250 '把 AWB 问题说清楚时，通常要同时描述四件事：当前光源类型、当前统计落点、当前 CCT/Tint 决策、以及颜色观感是 AWB 本身造成还是后续 CCM/tone mapping 一起造成。' @() 'gray'

    Save-Diagram $c $Path
}

function Draw-AWB-LightMap {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AWB Light Source Map' '用 R/G 与 B/G 平面理解光源分类、样本落点和调试思路'
    $g = $c.Graphics

    Draw-ChartAxes $g 120 240 980 620 'R/G' 'B/G'
    $regions = @(
        @{Name='A / Incandescent'; X=220; Y=650; W=180; H=120; C=[System.Drawing.Color]::FromArgb(255,237,213)},
        @{Name='TL84 / Fluorescent'; X=460; Y=480; W=200; H=140; C=[System.Drawing.Color]::FromArgb(220,252,231)},
        @{Name='D65 / Daylight'; X=700; Y=350; W=220; H=160; C=[System.Drawing.Color]::FromArgb(219,234,254)},
        @{Name='Shade / Cloudy'; X=880; Y=220; W=160; H=120; C=[System.Drawing.Color]::FromArgb(233,213,255)}
    )
    foreach ($r in $regions) {
        $brush = New-Object System.Drawing.SolidBrush($r.C)
        $pen = New-Pen 148 163 184 2
        Draw-RoundedRect $g $r.X $r.Y $r.W $r.H 18 $brush $pen
        $g.DrawString($r.Name, (New-FontSafe 'Microsoft YaHei' 12 ([System.Drawing.FontStyle]::Bold)), (New-Brush 17 24 39), ($r.X + 12), ($r.Y + 16))
        $brush.Dispose()
        $pen.Dispose()
    }

    $samples = @(
        @{X=320; Y=700; T='warm indoor'},
        @{X=540; Y=540; T='office TL84'},
        @{X=810; Y=410; T='daylight'},
        @{X=950; Y=260; T='shade'},
        @{X=620; Y=470; T='mixed light'}
    )
    foreach ($s in $samples) {
        $g.FillEllipse((New-Brush 37 99 235), ($s.X - 7), ($s.Y - 7), 14, 14)
        $g.DrawString($s.T, (New-FontSafe 'Microsoft YaHei' 10 ([System.Drawing.FontStyle]::Bold)), (New-Brush 17 24 39), ($s.X + 10), ($s.Y - 8))
    }

    Draw-Panel $g 1170 180 560 240 '怎么看这张图' @('横纵坐标不是绝对物理量，而是统计特征', '不同光源区域会形成聚类', '样本点落在边界时，更容易出现 decision 抖动') 'blue'
    Draw-Panel $g 1170 470 560 250 '为什么混光难' @('同一张图里可能同时有暖光和冷光', '中性候选点可能来自不同区域', '算法通常只能给出 dominant light 或折中结果') 'red'
    Draw-Panel $g 1170 780 560 180 '调试建议' @('结合 face weight 看最终结果是否更偏向肤色自然', '观察同场景下 decision 是否来回跨区域') 'green'

    Save-Diagram $c $Path
}

function Draw-AWB-MixedLight {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AWB Mixed Light Case' '混光场景下，算法需要在 dominant light、face protection 和稳定性之间折中'
    $g = $c.Graphics

    $sceneBrushLeft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 247, 220))
    $sceneBrushRight = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(224, 242, 254))
    $scenePen = New-Pen 148 163 184 2
    Draw-RoundedRect $g 80 170 760 520 18 $sceneBrushLeft $scenePen
    Draw-RoundedRect $g 840 170 760 520 18 $sceneBrushRight $scenePen
    $g.DrawString('室内暖光区域', (New-FontSafe 'Microsoft YaHei' 16 ([System.Drawing.FontStyle]::Bold)), (New-Brush 120 53 15), 120, 210)
    $g.DrawString('窗边自然光区域', (New-FontSafe 'Microsoft YaHei' 16 ([System.Drawing.FontStyle]::Bold)), (New-Brush 30 64 175), 890, 210)
    $g.FillEllipse((New-Brush 248 113 113), 690, 330, 120, 160)
    $g.DrawString('Face', (New-FontSafe 'Microsoft YaHei' 16 ([System.Drawing.FontStyle]::Bold)), (New-Brush 255 255 255), 722, 390)
    $g.DrawString('桌面白纸偏暖', (New-FontSafe 'Microsoft YaHei' 12 ([System.Drawing.FontStyle]::Regular)), (New-Brush 120 53 15), 180, 340)
    $g.DrawString('背景墙更中性', (New-FontSafe 'Microsoft YaHei' 12 ([System.Drawing.FontStyle]::Regular)), (New-Brush 30 64 175), 1060, 340)
    Draw-Arrow $g 780 410 1120 410 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-SmallLabel $g 830 380 'mixed boundary' ([System.Drawing.Color]::FromArgb(99,102,241))

    Draw-Panel $g 90 740 500 260 '算法会纠结什么' @('到底听室内暖光还是窗外冷光', '人脸应该更自然还是白纸更中性', '切角度时要不要快速改 decision') 'orange'
    Draw-Panel $g 650 740 500 260 '稳定策略' @('dominant light 选择 + face weight', '对边界场景做 temporal smooth', '避免一帧暖一帧冷的观感跳变') 'green'
    Draw-Panel $g 1210 740 500 260 '调试时记录' @('当前 ROI 和 face weight', '当前 decision / CCT / Tint', '切角度前后 gain 是否连续', '肤色是否比白纸更值得优先保护') 'purple'

    $sceneBrushLeft.Dispose()
    $sceneBrushRight.Dispose()
    $scenePen.Dispose()
    Save-Diagram $c $Path
}

function Draw-AWB-DebugSheet {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'AWB Debug Sheet' '把颜色问题拆成偏黄、偏绿、跳变、肤色异常四类来定位'
    $g = $c.Graphics

    Draw-Panel $g 60 150 390 350 '偏黄 / 偏暖' @('确认环境是否本来就是暖光', '看 CCT 是否估得过低', '看是不是策略故意保氛围感') 'orange'
    Draw-Panel $g 490 150 390 350 '偏绿 / 洋红异常' @('看 Tint 是否异常', '看荧光灯分类是否正确', '看 CCM 是否放大了偏差') 'green'
    Draw-Panel $g 920 150 390 350 '来回跳色' @('看 temporal smooth', '看 decision 是否频繁跨区域', '看 face detect 是否改变权重') 'blue'
    Draw-Panel $g 1350 150 390 350 '肤色不自然' @('看 face weight 是否足够', '看 AWB 与 CCM 的联动', '确认是不是后处理而不只是 AWB') 'purple'

    Draw-Panel $g 120 590 1560 300 '调试记录模板' @('场景: 室内暖光 / 日光 / 阴影 / 混光', '现象: 白纸偏黄、肤色偏青、预览来回跳', '参数: R/G、B/G、CCT、Tint、AWB gains、decision、face weight', '判断: 当前光源判断错，还是策略在做主观取舍', '验证: 换灯区、换角度、去掉人脸、比较前后多帧') 'gray'

    Save-Diagram $c $Path
}

function Draw-ISP-FullPipeline {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'ISP Full Pipeline' '把 RAW 到 Preview / JPEG 的主要图像处理链和 3A 统计抽头放在一张图里'
    $g = $c.Graphics

    $boxes = @(
        @{X=70; Y=220; W=150; H=72; T='Sensor RAW'},
        @{X=250; Y=220; W=160; H=72; T='BLC'},
        @{X=440; Y=220; W=160; H=72; T='BPC'},
        @{X=630; Y=220; W=180; H=72; T='LSC'},
        @{X=840; Y=220; W=180; H=72; T='Demosaic'},
        @{X=1050; Y=220; W=180; H=72; T='Noise Reduction'},
        @{X=1260; Y=220; W=160; H=72; T='AWB + CCM'},
        @{X=1450; Y=220; W=180; H=72; T='Gamma / Tone'},
        @{X=1650; Y=220; W=120; H=72; T='Output'}
    )
    foreach ($b in $boxes) { Draw-FlowBox $g $b.X $b.Y $b.W $b.H $b.T ([System.Drawing.Color]::FromArgb(224,231,255)) }
    for ($i = 0; $i -lt ($boxes.Count - 1); $i++) {
        $x1 = $boxes[$i].X + $boxes[$i].W
        $x2 = $boxes[$i+1].X
        Draw-Arrow $g $x1 ($boxes[$i].Y + 36) $x2 ($boxes[$i+1].Y + 36) ([System.Drawing.Color]::FromArgb(59,130,246))
    }

    Draw-FlowBox $g 700 420 220 72 'AE / AF / AWB Stats Tap' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-Arrow $g 720 292 810 420 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1140 292 920 420 ([System.Drawing.Color]::FromArgb(139,92,246))

    Draw-Panel $g 60 560 400 320 '前端校正' @('BLC: 去黑电平偏移', 'BPC: 修坏点', 'LSC: 修暗角和边缘偏色', '前端问题通常会直接影响后面所有处理') 'blue'
    Draw-Panel $g 500 560 400 320 '重建与降噪' @('Demosaic: 从 Bayer 恢复 RGB', 'NR: 抑制亮度和色度噪声', '这里的取舍常决定细节和塑料感') 'green'
    Draw-Panel $g 940 560 400 320 '颜色链路' @('AWB gain 把白点拉回中性', 'CCM 做颜色空间校正', 'Gamma / tone mapping 影响主观观感') 'orange'
    Draw-Panel $g 1380 560 360 320 '最终输出' @('Preview / Video / JPEG 不一定完全同策略', '后级 sharpening 会改变清晰感', '问题定位时要区分输入错误和后处理 trade-off') 'purple'

    Save-Diagram $c $Path
}

function Draw-ISP-BlockMap {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'ISP Block Map' '把 IFE / BPS / IPE / JPEG 与 3A、tuning、memory flow 的关系放在一张图里'
    $g = $c.Graphics

    Draw-FlowBox $g 180 190 230 90 'Sensor + CSI PHY' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 520 190 220 90 'IFE Front-End' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 850 120 220 90 'BPS' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 850 260 220 90 'IPE' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 1180 190 220 90 'JPEG / Output' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 520 420 220 90 'Stats Blocks' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-FlowBox $g 850 420 220 90 '3A Algorithms' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-FlowBox $g 1180 420 220 90 'Tuning / Chromatix' ([System.Drawing.Color]::FromArgb(243,232,255))

    Draw-Arrow $g 410 235 520 235 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 740 235 850 165 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 740 235 850 305 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 1070 235 1180 235 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 630 280 630 420 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 740 465 850 465 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1070 465 1180 465 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1290 420 1290 280 ([System.Drawing.Color]::FromArgb(22,163,74))
    Draw-Arrow $g 960 420 960 350 ([System.Drawing.Color]::FromArgb(22,163,74))

    Draw-Panel $g 70 620 500 300 '你看源码时可这样对号入座' @('IFE: 前端采集、部分统计和基础处理', 'BPS: 离线/中间处理块', 'IPE: 后级图像增强和颜色处理', 'Stats / 3A / tuning 是贯穿整条链路的控制面') 'blue'
    Draw-Panel $g 650 620 500 300 '问题容易出在哪' @('stats 没出来: 3A 决策跟不上', 'tuning 不对: 色彩、锐化、降噪全异常', 'memory / packet 不通: request 直接不出图') 'red'
    Draw-Panel $g 1230 620 500 300 '读代码顺序建议' @('先看 session / pipeline / node', '再看具体 HWL block', '最后把 3A 和 tuning update 回填进来') 'green'

    Save-Diagram $c $Path
}

function Draw-ISP-ProblemMap {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'ISP Image Problem Map' '把常见画质现象和可能的 3A / ISP 模块映射到一起'
    $g = $c.Graphics

    Draw-Panel $g 60 150 390 350 '亮度类问题' @('偏暗: AE 目标或约束', '高光死白: AE / HDR / tone mapping', '暗部发灰: BLC / tone mapping') 'orange'
    Draw-Panel $g 490 150 390 350 '颜色类问题' @('偏黄 / 偏绿: AWB / CCM', '肤色怪: AWB + CCM + tone', '边缘偏色: LSC / demosaic') 'blue'
    Draw-Panel $g 920 150 390 350 '细节类问题' @('发糊: AF / NR 过强', '伪色彩边: demosaic', '过锐白边: sharpening') 'purple'
    Draw-Panel $g 1350 150 390 350 '噪声类问题' @('颗粒大: AE gain 高', '彩噪明显: NR 弱', '细节塑料感: NR 太强') 'green'

    Draw-Panel $g 150 590 1500 310 '最佳实践' @('先分问题类别，再定位是 3A 输入、ISP block 还是主观策略取舍', '不要只盯一张 JPEG，下判断前最好结合 RAW、预览、log 和场景信息', '一旦遇到亮度、颜色、噪声同时异常，优先回看 AE / AWB / tuning 是否联动失衡') 'gray'

    Save-Diagram $c $Path
}

function Draw-ISP-DebugFlow {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'ISP Debug Flow' '从一张异常图出发，先分类，再决定先看 3A、stats、tuning 还是具体 block'
    $g = $c.Graphics

    Draw-FlowBox $g 760 140 280 80 '拿到异常图像' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-FlowBox $g 760 280 280 80 '先分问题类型' ([System.Drawing.Color]::FromArgb(224,231,255))
    Draw-Arrow $g 900 220 900 280 ([System.Drawing.Color]::FromArgb(59,130,246))

    Draw-FlowBox $g 180 450 240 80 '亮度' ([System.Drawing.Color]::FromArgb(255,247,237))
    Draw-FlowBox $g 540 450 240 80 '颜色' ([System.Drawing.Color]::FromArgb(239,246,255))
    Draw-FlowBox $g 900 450 240 80 '清晰度' ([System.Drawing.Color]::FromArgb(245,243,255))
    Draw-FlowBox $g 1260 450 240 80 '噪声' ([System.Drawing.Color]::FromArgb(240,253,250))
    Draw-Arrow $g 820 360 300 450 ([System.Drawing.Color]::FromArgb(249,115,22))
    Draw-Arrow $g 860 360 660 450 ([System.Drawing.Color]::FromArgb(59,130,246))
    Draw-Arrow $g 940 360 1020 450 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 980 360 1380 450 ([System.Drawing.Color]::FromArgb(16,185,129))

    Draw-Panel $g 60 620 390 290 '亮度分支' @('先看 AE / targetY / exposure', '再看 HDR / tone mapping', '确认是输入曝光不足还是后处理映射') 'orange'
    Draw-Panel $g 490 620 390 290 '颜色分支' @('先看 AWB / CCT / Tint / gains', '再看 CCM / gamma', '确认是光源判断错还是颜色矩阵不合适') 'blue'
    Draw-Panel $g 920 620 390 290 '清晰度分支' @('先看 AF 是否合焦', '再看 demosaic / sharpen', '确认是失焦还是后处理过强') 'purple'
    Draw-Panel $g 1350 620 390 290 '噪声分支' @('先看 AE gain', '再看 NR 强度', '确认是亮度成本还是降噪 trade-off') 'green'

    Save-Diagram $c $Path
}

function Draw-QCOM-Overview {
    param([string]$Path)
    $c = New-Canvas 1800 1100 'QCOM Camera Stack Overview' 'Android Framework -> HAL3 -> CHI/CamX -> CSL -> camera-kernel -> Sensor/IFE/ICP'
    $g = $c.Graphics
    $items = @(
        @{X=70;Y=210;W=200;H=80;T='App / CameraX'},
        @{X=320;Y=210;W=220;H=80;T='CameraService'},
        @{X=600;Y=210;W=220;H=80;T='HAL3 Entry'},
        @{X=880;Y=210;W=220;H=80;T='CHI Override'},
        @{X=1160;Y=210;W=220;H=80;T='CamX Session / Pipeline'},
        @{X=1440;Y=210;W=220;H=80;T='CSL / KMD'}
    )
    foreach ($i in $items) { Draw-FlowBox $g $i.X $i.Y $i.W $i.H $i.T ([System.Drawing.Color]::FromArgb(224,231,255)) }
    for ($j=0; $j -lt ($items.Count - 1); $j++) {
        Draw-Arrow $g ($items[$j].X + $items[$j].W) ($items[$j].Y + 40) ($items[$j+1].X) ($items[$j+1].Y + 40) ([System.Drawing.Color]::FromArgb(59,130,246))
    }
    Draw-FlowBox $g 1180 470 220 80 'cam_req_mgr' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-FlowBox $g 900 650 220 80 'cam_isp' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-FlowBox $g 1180 650 220 80 'cam_sensor' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-FlowBox $g 1460 650 220 80 'cam_icp' ([System.Drawing.Color]::FromArgb(243,232,255))
    Draw-Arrow $g 1550 290 1290 470 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1290 550 1010 650 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1290 550 1290 650 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Arrow $g 1290 550 1570 650 ([System.Drawing.Color]::FromArgb(139,92,246))
    Draw-Panel $g 90 820 1600 190 '建议从 HAL3 request 入口开始看，再沿着 session/pipeline -> CSL -> cam_req_mgr -> ISP/sensor 逐层下钻。3A 相关再从 stats parser 和 tuning update 回看。' @() 'gray'
    Save-Diagram $c $Path
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..')

Draw-AE-Pipeline (Join-Path $root 'AE\images\ae-pipeline.png')
Draw-AE-Banding (Join-Path $root 'AE\images\ae-banding-case.png')
Draw-AE-Checklist (Join-Path $root 'AE\images\ae-debug-checklist.png')
Draw-AE-LogExample (Join-Path $root 'AE\images\ae-log-example.png')

Draw-AF-StateMachine (Join-Path $root 'AF\images\af-state-machine.png')
Draw-AF-SearchCurve (Join-Path $root 'AF\images\af-search-curve.png')
Draw-AF-PDAF (Join-Path $root 'AF\images\af-pdaf-flow.png')
Draw-AF-FailCase (Join-Path $root 'AF\images\af-fail-case.png')

Draw-AWB-Pipeline (Join-Path $root 'AWB\images\awb-pipeline.png')
Draw-AWB-LightMap (Join-Path $root 'AWB\images\awb-light-source-map.png')
Draw-AWB-MixedLight (Join-Path $root 'AWB\images\awb-mixed-light-case.png')
Draw-AWB-DebugSheet (Join-Path $root 'AWB\images\awb-debug-sheet.png')

Draw-ISP-FullPipeline (Join-Path $root 'ISP\images\isp-full-pipeline.png')
Draw-ISP-BlockMap (Join-Path $root 'ISP\images\isp-block-map.png')
Draw-ISP-ProblemMap (Join-Path $root 'ISP\images\isp-image-problem-map.png')
Draw-ISP-DebugFlow (Join-Path $root 'ISP\images\isp-debug-flow.png')

Draw-QCOM-Overview (Join-Path $root 'QCOM\images\qcom-stack-overview.png')

Write-Output 'Generated camera diagrams.'

