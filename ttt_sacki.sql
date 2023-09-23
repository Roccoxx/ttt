-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 19-08-2022 a las 04:37:20
-- Versión del servidor: 10.4.17-MariaDB
-- Versión de PHP: 8.0.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `ttt`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ttt_ermec_accounts`
--

CREATE TABLE `ttt_ermec_accounts` (
  `id_user` int(10) NOT NULL,
  `Jugador` varchar(32) NOT NULL,
  `Logros` varchar(200) DEFAULT NULL,
  `TeamKill` varchar(100) DEFAULT NULL,
  `MutearCR` int(4) UNSIGNED NOT NULL DEFAULT 0,
  `OcultarMotd` int(4) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Disparadores `ttt_ermec_accounts`
--
DELIMITER $$
CREATE TRIGGER `insertarestadisticas` AFTER INSERT ON `ttt_ermec_accounts` FOR EACH ROW INSERT INTO ttt_ermec_statistics (id_user, Jugador) VALUES (NEW.id_user, NEW.Jugador)
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ttt_ermec_statistics`
--

CREATE TABLE `ttt_ermec_statistics` (
  `id_user` int(10) NOT NULL,
  `Jugador` varchar(32) NOT NULL,
  `Segundos` int(10) NOT NULL DEFAULT 0,
  `Puntos` int(10) NOT NULL DEFAULT 0,
  `det_asesinados` int(10) NOT NULL DEFAULT 0,
  `inn_asesinados` int(10) NOT NULL DEFAULT 0,
  `tra_asesinados` int(10) NOT NULL DEFAULT 0,
  `cantidad_asesinatos` int(10) NOT NULL DEFAULT 0,
  `cantidad_muertes` int(10) NOT NULL DEFAULT 0,
  `damage_correcto` int(10) NOT NULL DEFAULT 0,
  `damage_incorrecto` int(10) NOT NULL DEFAULT 0,
  `asesinatos_correctos` int(10) NOT NULL DEFAULT 0,
  `asesinatos_incorrectos` int(10) NOT NULL DEFAULT 0,
  `rondas_de_traidor` int(10) NOT NULL DEFAULT 0,
  `rondas_de_innocente` int(10) NOT NULL DEFAULT 0,
  `rondas_de_detective` int(10) NOT NULL DEFAULT 0,
  `rondas_jugadas` int(10) NOT NULL DEFAULT 0,
  `rondas_ganadas` int(10) NOT NULL DEFAULT 0,
  `rondas_ganadas_traidor` int(10) NOT NULL DEFAULT 0,
  `maximo_karma` int(10) NOT NULL DEFAULT 0,
  `c4_plantadas` int(10) NOT NULL DEFAULT 0,
  `c4_explotadas` int(10) NOT NULL DEFAULT 0,
  `c4_defuseadas` int(10) NOT NULL DEFAULT 0,
  `c4_asesinatos` int(10) NOT NULL DEFAULT 0,
  `knife_asesinatos` int(10) NOT NULL DEFAULT 0,
  `newton_asesinatos` int(10) NOT NULL DEFAULT 0,
  `jihad_asesinatos` int(10) NOT NULL DEFAULT 0,
  `usp_asesinatos` int(10) NOT NULL DEFAULT 0,
  `golden_asesinatos` int(10) NOT NULL DEFAULT 0,
  `mina_asesinatos` int(10) NOT NULL DEFAULT 0,
  `estacion_asesinatos` int(10) NOT NULL DEFAULT 0,
  `hit_mortal_asesinatos` int(10) NOT NULL DEFAULT 0,
  `falso_detective` int(10) NOT NULL DEFAULT 0,
  `jugadores_desarmados` int(10) NOT NULL DEFAULT 0,
  `jugadores_desmarcados` int(10) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `ttt_ermec_accounts`
--
ALTER TABLE `ttt_ermec_accounts`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `Jugador` (`Jugador`);

--
-- Indices de la tabla `ttt_ermec_statistics`
--
ALTER TABLE `ttt_ermec_statistics`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `Jugador` (`Jugador`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `ttt_ermec_accounts`
--
ALTER TABLE `ttt_ermec_accounts`
  MODIFY `id_user` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `ttt_ermec_statistics`
--
ALTER TABLE `ttt_ermec_statistics`
  MODIFY `id_user` int(10) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
