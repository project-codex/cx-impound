SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE TABLE `impounded_vehicles` (
  `id` int(11) NOT NULL,
  `pd_cid` varchar(255) NOT NULL,
  `cid` varchar(255) NOT NULL,
  `vehicle` varchar(255) NOT NULL,
  `hash` varchar(255) NOT NULL,
  `plate` varchar(255) NOT NULL,
  `depot_price` int(255) NOT NULL DEFAULT 0,
  `impound_time` int(255) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `impounded_vehicles`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `impounded_vehicles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;
COMMIT;
