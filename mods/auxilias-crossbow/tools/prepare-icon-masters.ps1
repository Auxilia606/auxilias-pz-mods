param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$modRoot = Split-Path -Parent $PSScriptRoot
$iconRoot = Join-Path $modRoot 'source-assets\icons'
$generatedRoot = Join-Path $iconRoot 'generated'

# Mechanical framing/downsampling only. Artwork and transparency come from ImageGen.
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class AuxiliaIconBounds {
    // A compact shared material palette based on the inspected vanilla wood,
    // forged spearhead and chipped-stone icons. This is output quantization,
    // not geometry drawing or replacement of the generated artwork.
    private static readonly int[] Palette = {
        0x1d1c1c,0x302720,0x423125,0x513d2e,0x653d2e,0x6a5343,
        0x7a604e,0x8b6d55,0x997c65,0xae9073,
        0x303030,0x494949,0x595959,0x6d6d6d,0x838383,
        0x4d4c47,0x5f5e58,0x73726a,0x81807a,0x96948b,
        0xada99a,0xc2b493,0xdfd1ae,0xede5ce
    };
    public static void Quantize(Bitmap image) {
        for (int y=0;y<image.Height;y++) for (int x=0;x<image.Width;x++) {
            Color c=image.GetPixel(x,y);
            if(c.A<96) { image.SetPixel(x,y,Color.Transparent); continue; }
            int best=Palette[0], distance=int.MaxValue;
            foreach(int rgb in Palette) {
                int dr=c.R-((rgb>>16)&255), dg=c.G-((rgb>>8)&255), db=c.B-(rgb&255);
                int d=dr*dr+dg*dg+db*db;
                if(d<distance) { distance=d; best=rgb; }
            }
            image.SetPixel(x,y,Color.FromArgb(255,(best>>16)&255,(best>>8)&255,best&255));
        }
    }
    public static Rectangle Visible(Bitmap image) {
        var rect = new Rectangle(0, 0, image.Width, image.Height);
        var data = image.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int left=image.Width, top=image.Height, right=-1, bottom=-1;
        try {
            byte[] row = new byte[image.Width * 4];
            for (int y=0; y<image.Height; y++) {
                Marshal.Copy(IntPtr.Add(data.Scan0, y*data.Stride), row, 0, row.Length);
                for (int x=0; x<image.Width; x++) {
                    // Ignore near-invisible generation specks when computing framing;
                    // retained artwork alpha is never replaced with a painted background.
                    if (row[x*4+3] < 8) continue;
                    left=Math.Min(left,x); right=Math.Max(right,x);
                    top=Math.Min(top,y); bottom=Math.Max(bottom,y);
                }
            }
        } finally { image.UnlockBits(data); }
        if (right<left) throw new InvalidOperationException("Empty generated icon");
        return Rectangle.FromLTRB(left,top,right+1,bottom+1);
    }
}
'@ -ReferencedAssemblies System.Drawing.Common,System.Drawing.Primitives,System.Runtime.InteropServices

$framing = [ordered]@{
    AuxiliaImprovisedCrossbow = 112
    AuxiliaReinforcedCrossbow = 112
    AuxiliaHeavyArbalest = 112
    AuxiliaCrossbowBolt = 112
    AuxiliaStoneCrossbowBolt = 112
    AuxiliaBrokenBolt = 76
    AuxiliaBrokenStoneBolt = 76
    AuxiliaBoltShaft = 104
    AuxiliaBoltHead = 88
    AuxiliaStoneBoltHead = 88
}

foreach ($entry in $framing.GetEnumerator()) {
    $fileName = "Item_$($entry.Key).png"
    $source = [System.Drawing.Bitmap]::new((Join-Path $generatedRoot $fileName))
    $master = [System.Drawing.Bitmap]::new(128,128,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $bounds = [AuxiliaIconBounds]::Visible($source)
        $scale = $entry.Value / [double][Math]::Max($bounds.Width,$bounds.Height)
        $width = [int][Math]::Round($bounds.Width*$scale)
        $height = [int][Math]::Round($bounds.Height*$scale)
        $target = [System.Drawing.Rectangle]::new([int][Math]::Floor((128-$width)/2),[int][Math]::Floor((128-$height)/2),$width,$height)
        $graphics = [System.Drawing.Graphics]::FromImage($master)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImage($source,$target,$bounds,[System.Drawing.GraphicsUnit]::Pixel)
        } finally { $graphics.Dispose() }
        # Author at the actual game grid, then store the 4x pixel master. The
        # runtime sync uses nearest-neighbor so it introduces no new edge colors.
        $native = [System.Drawing.Bitmap]::new(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($native)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($master,0,0,32,32)
            } finally { $graphics.Dispose() }
            [AuxiliaIconBounds]::Quantize($native)
            $graphics = [System.Drawing.Graphics]::FromImage($master)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $graphics.DrawImage($native,0,0,128,128)
            } finally { $graphics.Dispose() }
        } finally { $native.Dispose() }
        $master.Save((Join-Path $iconRoot $fileName),[System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "$fileName => 128px, visible extent ${width}x${height}"
    } finally { $master.Dispose(); $source.Dispose() }
}
