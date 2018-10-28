#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-
# 
# define about KML template

# KML header template
KML_HEADER = <<EOS
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://earth.google.com/kml/2.2\">
<Document>
EOS

# GOOD style template
KML_GOOD_STYLE = <<EOS
  <Style id=\"style1\">
    <IconStyle>
      <Icon>
        <href>http://maps.google.com/mapfiles/ms/micons/blue-dot.png</href>
      </Icon>
    </IconStyle>
  </Style>
EOS

# FAIR style template
KML_FAIR_STYLE = <<EOS
  <Style id=\"style2\">
    <IconStyle>
      <Icon>
        <href>http://maps.google.com/mapfiles/ms/micons/yellow-dot.png</href>
      </Icon>
    </IconStyle>
  </Style>
EOS

# POOR style template
KML_POOR_STYLE = <<EOS
  <Style id=\"style3\">
    <IconStyle>
      <Icon>
        <href>http://maps.google.com/mapfiles/ms/micons/red-dot.png</href>
      </Icon>
    </IconStyle>
  </Style>
EOS

# GOOD Polygon style template. Polygon Color is Blue.
GOOD_POLY_STYLE = <<EOS
<StyleMap  id=\"style4\">
  <Pair>
    <key>normal</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>80FF0000</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
  <Pair>
    <key>highlight</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>FFFFFFFF</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
</StyleMap>
EOS

# FAIR Polygon style template. Polygon Color is Yellow.
FAIR_POLY_STYLE = <<EOS
<StyleMap  id=\"style5\">
  <Pair>
    <key>normal</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>8000FFFF</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
  <Pair>
    <key>highlight</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>FFFFFFFF</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
</StyleMap>
EOS

# POOR Polygon style template. Polygon Color is Red
POOR_POLY_STYLE = <<EOS
<StyleMap id=\"style6\">
  <Pair>
    <key>normal</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>800000FF</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
  <Pair>
    <key>highlight</key>
    <Style>
      <LineStyle>
        <color>40FFFFFF</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>FFFFFFFF</color>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
    </Style>
  </Pair>
</StyleMap>
EOS

# Station style template
STATION_STYLE = <<EOS
  <Style id="station">
    <IconStyle>
      <scale>0.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/placemark_square_maps.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
EOS

# Yamanote Line template
YAMANOTE_LINE_STYLE = <<EOS
  <Style id="y_line">
    <LineStyle>
      <color>7F009900</color>
      <width>6</width>
    </LineStyle>
  </Style>
EOS

# New Tokaido Line style template
NEW_TOKAIDO_LINE_STYLE = <<EOS
  <Style id="t_s_line">
    <LineStyle>
      <color>7FFF3333</color>
      <width>6</width>
    </LineStyle>
  </Style>
EOS

# Yamanote Line folder template
KML_YAMANOTE_FOLDER = <<EOS
  <Folder>
    <name>Yamanote Line</name>
    <open>0</open>
    <Folder>
      <name>Data</name>
      <open>0</open>
    %s
    </Folder>
    <Folder>
      <name>line</name>
      <open>0</open>
    %s  </Folder>
  </Folder>
EOS

# New Tokaido Line folder template
KML_NEW_TOKAI_FOLDER = <<EOS
  <Folder>
    <name>New Tokai Line</name>
    <open>0</open>
    <Folder>
      <name>Data</name>
      <open>0</open>
    %s
    </Folder>
    <Folder>
      <name>line</name>
      <open>0</open>
    %s  </Folder>
  </Folder>
EOS

# Other point folder template
KML_OTHER_FOLDER = <<EOS
  <Folder>
    <name>Other</name>
    <open>0</open>
  %s  </Folder>
EOS

# Hanrei part template
KML_HANREI_PART = <<EOS
  <ScreenOverlay>
    <name>hanrei</name>
    <visibility>1</visibility>
    <Icon>
      <href>hanrei.png</href>
    </Icon>
    <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="0.01" y="0.99" xunits="fraction" yunits="fraction"/>
    <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
    <size x="0.15" y="0.20" xunits="fraction" yunits="fraction"/>
  </ScreenOverlay>
EOS

# KML body template
KML_BODY_PART = <<EOS
  <Placemark>
    <name>Around %s</name>
    <styleUrl>#style%d</styleUrl>
    <snippet></snippet>
    <description><![CDATA[
    <h4>%s ~ %s</h4>
    <table border="1">
      <tr bgcolor="royalblue" style="color:white">
        <td><font size="4"><b>ITEM</b></font></td><td colspan="2"><font size="4"><b>VALUE</b></font></td>
      </tr>
      <tr>
        <td bgcolor="lavender">up<br>throughput[bps]</td><td colspan="2">%f</td>
      </tr>
      <tr>
        <td bgcolor="lavender">down<br>throughput[bps]</td><td colspan="2">%f</td>
      </tr>
      <tr>
        <td bgcolor="lavender">distance[m]</td><td colspan="2">%s</td>
      </tr>
EOS

KML_PIN_BODY_PART = <<EOS
  <Placemark>
    <styleUrl>#style%d</styleUrl>
    <snippet></snippet>
    <description><![CDATA[
    <h4>%s ~ %s</h4>
    <table border="1">
      <tr bgcolor="royalblue" style="color:white">
        <td><font size="4"><b>ITEM</b></font></td><td colspan="2"><font size="4"><b>VALUE</b></font></td>
      </tr>
      <tr>
        <td bgcolor="lavender">up<br>throughput[bps]</td><td colspan="2">%f</td>
      </tr>
      <tr>
        <td bgcolor="lavender">down<br>throughput[bps]</td><td colspan="2">%f</td>
      </tr>
      <tr>
        <td bgcolor="lavender">distance[m]</td><td colspan="2">%s</td>
      </tr>
EOS

# Request part header template at kml
KML_REQUEST_HEAD = <<EOS
      <tr>
        <td bgcolor="lavender" rowspan="%d">request host</td>
EOS

# Request part body template at kml
KML_REQUEST_PART = <<EOS
        <td>%s</td>
      </tr>
EOS

# Request header part template at html
HTML_REQUEST_HEAD = <<EOS
<html>
<body>
EOS

# Request body part template at html
HTML_REQUEST_PART = <<EOS
    <tr><td>%s</td></tr>
EOS

# Request footer part template at html
HTML_REQUEST_FOOT = <<EOS
</body>
</html>
EOS

# Src ipaddr part template
KML_IPADDR_PART = <<EOS
      <tr>
        <td bgcolor="lavender">src ipaddr</td><td>%s</td>
      </tr>
EOS

# Polygon part template
KML_POLY_PART = <<EOS
    </table>
    ]]></description>
    <Polygon>
      <outerBoundaryIs>
        <LinearRing>
          <tessellate>1</tessellate>
          <coordinates>
            %f,%f,0.000000
            %f,%f,0.000000
            %f,%f,0.000000
            %f,%f,0.000000
            %f,%f,0.000000
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
    </Polygon>
  </Placemark>
EOS

KML_PIN_PART = <<EOS
    </table>
    ]]></description>
    <Point>
      <coordinates>
            %f,%f,0.000000
      </coordinates>
    </Point>
  </Placemark>
EOS

# KML body end part template
KML_BODY_END = <<EOS
    </table>
    ]]></description>
    <Point>
      <coordinates>%f,%f</coordinates>
    </Point>
  </Placemark>
EOS

# Station of Yamanote Line part template
YAMANOTE_BODY = <<EOS
  <Placemark>
    <name>大崎</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.728424,35.619743,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>五反田</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.723495,35.626389,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>品川</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.738876,35.628193,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>目黒</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.715652,35.633171,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>恵比寿</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.710342,35.646267,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>田町</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.747574,35.645702,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>渋谷</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.701477,35.658508,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>浜松町</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.757095,35.655239,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>新橋</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.758194,35.666451,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>原宿</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.702560,35.670807,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>代々木</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.702087,35.683861,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>新宿</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.700500,35.689674,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>新大久保</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.700226,35.701061,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>高田馬場</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.703598,35.712685,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>目白</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.706177,35.720402,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>池袋</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.710815,35.729843,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>大塚</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.728012,35.731758,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>巣鴨</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.740021,35.733570,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>駒込</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.747589,35.736740,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>有楽町</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.762772,35.674782,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>東京</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.767059,35.681187,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>神田</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.770889,35.691669,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>秋葉原</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.773087,35.698345,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>御徒町</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.774597,35.707092,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>上野</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.776489,35.713860,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>鶯谷</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.778702,35.720802,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>西日暮里</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.766678,35.732002,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>日暮里</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.770981,35.727791,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>田端</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.761612,35.737438,0.000000</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>YAMANOTE Line</name>
    <description><![CDATA[]]></description>
    <styleUrl>#y_line</styleUrl>
    <LineString>
      <tessellate>1</tessellate>
      <altitudeMode>clampToSeaFloor</altitudeMode>
      <coordinates>
        %s
      </coordinates>
    </LineString>
  </Placemark>
EOS

# Station of New Tokaido Line part template
NEW_TOKAIDO_BODY = <<EOS
  <Placemark>
    <name>東京</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.766084, 35.681382, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>品川</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.74044, 35.630152, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>新横浜</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.617585, 35.507456, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>小田原</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.154904, 35.25642, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>熱海</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>139.07776, 35.103217, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>三島</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>138.910627, 35.127152, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>新富士</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>138.663382, 35.142015, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>静岡</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>138.38884, 34.97171, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>掛川</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>138.014928, 34.769758, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>浜松</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>137.734442, 34.703741, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>豊橋</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>137.381651, 34.762811, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>三河安城</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>137.060662, 34.96897, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>名古屋</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>136.881637, 35.170694, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>岐阜羽島</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>136.685593, 35.315705, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>米原</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>136.290488, 35.314188, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>京都</name>
    <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <Point>
      <coordinates>135.757755, 34.985458, 0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
  <description><![CDATA[]]></description>
    <styleUrl>#station</styleUrl>
    <name>新大阪</name>
    <Point>
      <coordinates>135.500109,34.73348,0</coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name>New Tokaido Line</name>
    <description><![CDATA[]]></description>
    <styleUrl>#t_s_line</styleUrl>
    <LineString>
      <tessellate>1</tessellate>
      <altitudeMode>clampToSeaFloor</altitudeMode>
      <coordinates>
        %s
      </coordinates>
    </LineString>
  </Placemark>
EOS

# Color Style
EXT_COLOR_STYLE = <<EOS
  <Style id="style0">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/blue-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style1">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/red-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style2">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/green-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style3">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/ltblue-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style4">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/yellow-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style5">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/purple-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
  <Style id="style6">
    <IconStyle>
      <scale>0.8</scale>
      <Icon>
        <href>http://maps.gstatic.com/mapfiles/ms2/micons/pink-dot.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <scale>0.6</scale>
    </LabelStyle>
  </Style>
EOS

EXT_LINE_COLOR_STYLE = <<EOS
  <Style id="line_style0">
    <LineStyle>
      <color>CCFF3333</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style1">
    <LineStyle>
      <color>CC0000FF</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style2">
    <LineStyle>
      <color>CC00CC33</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style3">
    <LineStyle>
      <color>CCFFFF33</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style4">
    <LineStyle>
      <color>CC00CCFF</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style5">
    <LineStyle>
      <color>CCCC0066</color>
      <width>5</width>
    </LineStyle>
  </Style>
  <Style id="line_style6">
    <LineStyle>
      <color>CCFF99FF</color>
      <width>5</width>
    </LineStyle>
  </Style>
EOS

EXT_USER_FOLDER = <<EOS
  <Folder>
    <name>%s</name>
    <open>0</open>
EOS

EXT_PLACE_PART = <<EOS    
    <Placemark>
      <name>%s</name>
      <snippet></snippet>
      <description>%s
      
      %s ~ 
      %s</description>
      <styleUrl>#style%d</styleUrl>
      <Point>
        <coordinates>%f,%f,0</coordinates>
      </Point>
    </Placemark>
EOS

EXT_LINE_PART = <<EOS
    <Placemark>
      <styleUrl>#line_style%d</styleUrl>
      <LineString>
        <tessellate>1</tessellate>
        <coordinates>
          %f,%f,0 %f,%f,0
        </coordinates>
      </LineString>
    </Placemark>
EOS

# KML footer template
KML_FOOTER = <<EOS
</Document>
</kml>
EOS
