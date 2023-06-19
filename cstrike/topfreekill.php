<?php

$database['user'] = "root";
$database['pass'] = "";
$database['host'] = "localhost";
$database['db'] = "ttt_pijudo";
$database['tabla'] = "ttt_ermec_statistics";

@$db = new mysqli($database['host'], $database['user'], $database['pass'], $database['db']);
if($db->connect_error) {
    die('Error de Conexi&oacute;n: <strong>[ '.$db->connect_errno.' ] (<span style="color:red"> '.$db->connect_error.' </span>)</strong>');
}

$max = 10;
$query = $db->query('SELECT * FROM '.$database['tabla']) or die ("Error: ".mysqli_error($db));
if(count($query->fetch_array(MYSQLI_NUM))) {
    echo '<html><head><title>TOP '.$max.'</title></head><body bgcolor="#212121"><table border="0" cellpadding="5" cellspacing="0" style="box-shadow: 0px 0px 8px white; border-radius: 5px; width: 100%;min-width: 50%;">
            <tbody style="text-align:center;color:white;">
                <tr style="font-weight: bold;background-color: black;">
                    <td>
                        #
                    </td>
                    <td>
                        NOMBRE
                    </td>
                    <td>
                        FREEKILL
                    </td>
                </tr>';
                $n = 1;

                $query = $db->query('SELECT Jugador, asesinatos_incorrectos FROM `'.$database['tabla'].'` ORDER BY asesinatos_incorrectos DESC LIMIT '.$max) or die ("Error en la consulta: ".mysqli_error($db));
                $style1 = "color: rgb(255, 225, 0);text-shadow: 0px 0px 4px rgb(255, 108, 0);";
                $style_c1 = "background-color: rgb(60, 60, 60);";
                $style_c2 = "background-color: rgb(48, 48, 48);";
                $style=1;
                $css = "";
                while($top = $query->fetch_array(MYSQLI_ASSOC)) {
                    
                    if($n == 1) {
                        $css = 'style="'.$style_c1.$style1.'"';
                        $style = 0;
                    }
                    else if($style) {
                        $css = 'style="'.$style_c1.'"';
                        $style=0;
                    }
                    else {
                        
                        $css = 'style="'.$style_c2.'"';
                        $style=1;
                    }
                    echo '<tr '.$css.'>
                    <td>'.
                        $n
                    .'</td>
                    <td>'.
                        $top['Jugador']
                    .'</td>
                    <td>'.
                        $top['asesinatos_incorrectos']
                    .'</td>
                </tr>';
                    $n++;
                }
                echo '</tbody></table></body></html>';
    
}
else {
    echo "No hay datos que mostrar :(";
}
$query->free();

$db->close();
?>