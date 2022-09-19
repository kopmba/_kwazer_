-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : sam. 17 sep. 2022 à 12:09
-- Version du serveur :  10.4.14-MariaDB
-- Version de PHP : 7.2.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `kwazer`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `transfer` (OUT `_status` VARCHAR(20), OUT `shippingid` MEDIUMINT, OUT `reason` TEXT, OUT `cmdpayedid` MEDIUMINT)  NO SQL
BEGIN

set @producerid = (select producerid from commandpayed where cpid = cmdpayedid);
set @consumerid = (select consumerid from commandpayed where cpid = cmdpayedid);
set @connid = (select conectorid from commandpayed where cpid = cmdpayedid);
set @payid = (select payid from payment where commandpayedid = cmdpayedid);

set @fullname = (select fullname from profile where proid = @consumerid);
set @amount = (select totalamount from commandpayed where cpid = cmdpayedid);

if _status = 'REFUSED' THEN

	INSERT INTO `messagenotification` (`profileid`, `commandpayedid`, `message`, `created`, `edited`) VALUES (shippingid, cmdpayedid, 'A payment has been refused by the customer '+@fullname+ '. Reason : '+reason, now(), now());
    
    INSERT INTO `transfer` (`payid`, `profileid`, `connectorid`, `amount`, `created`, `edited`) VALUES (@payid, @consumerid, @connid, @amount - 700, now(), now());
    
    UPDATE `commission` SET `amount`=old.amount + 200,`edited`= now() WHERE `profileid` = @connid; 
    
    UPDATE `commission` SET `amount`=old.amount + 500,`edited`= now() WHERE `profileid` = shippingid; 
    

else

	INSERT INTO `transfer` (`payid`, `profileid`, `connectorid`, `amount`, `created`, `edited`) VALUES (@payid, @consumerid, @connid, @amount * 0.98, now(), now());
    UPDATE `commission` SET `amount`=old.amount + @amount*0.02,`edited`= now() WHERE `profileid` = @connid; 
    
end if;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `accountstate`
--

CREATE TABLE `accountstate` (
  `astateid` mediumint(9) NOT NULL,
  `connectorid` mediumint(9) NOT NULL,
  `profileid` varchar(20) NOT NULL,
  `amount` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `accountstate`
--

INSERT INTO `accountstate` (`astateid`, `connectorid`, `profileid`, `amount`, `created`, `edited`) VALUES
(1, 0, '5', 25, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `accountstate_list`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `accountstate_list` (
`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`phone` decimal(10,0)
,`proid` mediumint(9)
,`userid` varchar(80)
,`amount` mediumint(9)
,`connectorid` mediumint(9)
,`astateid` mediumint(9)
);

-- --------------------------------------------------------

--
-- Structure de la table `category`
--

CREATE TABLE `category` (
  `caid` mediumint(9) NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `category`
--

INSERT INTO `category` (`caid`, `name`, `description`, `created`, `edited`) VALUES
(1, 'clothes', 'This category give information about clothes product', '2022-08-11 13:44:37', '2022-08-11 13:44:37'),
(2, 'shoes', 'This category give information about shoes product', '2022-08-11 13:44:37', '2022-08-11 13:44:37');

-- --------------------------------------------------------

--
-- Structure de la table `commandpayed`
--

CREATE TABLE `commandpayed` (
  `cpid` mediumint(9) NOT NULL,
  `refcmd` varchar(200) NOT NULL,
  `consumerid` mediumint(9) NOT NULL,
  `producerid` mediumint(9) NOT NULL,
  `conectorid` mediumint(9) NOT NULL,
  `totalamount` mediumint(9) DEFAULT 2010,
  `_status` varchar(20) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `commandpayed`
--

INSERT INTO `commandpayed` (`cpid`, `refcmd`, `consumerid`, `producerid`, `conectorid`, `totalamount`, `_status`, `created`, `edited`) VALUES
(9, '91032ad7bbcb6cf72875e8e8207dcfba80173f7c', 2, 1, 5, 25, 'PAID', '2022-08-11 21:44:27', '2022-08-11 21:44:27');

--
-- Déclencheurs `commandpayed`
--
DELIMITER $$
CREATE TRIGGER `update_cmdpayed` AFTER INSERT ON `commandpayed` FOR EACH ROW begin

set @consumer = (select phone from profile where proid = new.consumerid);

INSERT INTO `payment`(`commandpayedid`, `opname`, `senderid`, `receiverid`, `amount`, `created`, `edited`) VALUES (new.cpid,'MTN',@consumer,1545786315,new.totalamount,now(),now());

INSERT INTO `coupon`(`producerid`, `connectorid`, `commandpayedid`, `created`, `edited`) VALUES (new.producerid,new.conectorid,new.cpid,now(),now());


INSERT INTO `commission` (`profileid`, `commandpayedid`, `amount`, `created`, `edited`) VALUES (new.conectorid, new.cpid, 0, now(), now());

INSERT INTO `shipping` (`cmdpayedid`, `transporterid`, `_status`, `reason`, `created`, `edited`) VALUES (new.cpid, 0, 'PENDING', '', now(), now());

end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `commission`
--

CREATE TABLE `commission` (
  `aid` mediumint(9) NOT NULL,
  `profileid` mediumint(9) NOT NULL,
  `commandpayedid` mediumint(9) NOT NULL,
  `amount` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `commission`
--

INSERT INTO `commission` (`aid`, `profileid`, `commandpayedid`, `amount`, `created`, `edited`) VALUES
(1, 5, 9, 0, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

-- --------------------------------------------------------

--
-- Structure de la table `coupon`
--

CREATE TABLE `coupon` (
  `coid` mediumint(9) NOT NULL,
  `producerid` mediumint(9) NOT NULL,
  `connectorid` mediumint(9) NOT NULL,
  `commandpayedid` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `coupon`
--

INSERT INTO `coupon` (`coid`, `producerid`, `connectorid`, `commandpayedid`, `created`, `edited`) VALUES
(1, 1, 5, 9, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

--
-- Déclencheurs `coupon`
--
DELIMITER $$
CREATE TRIGGER `send_notification` AFTER INSERT ON `coupon` FOR EACH ROW BEGIN

set @amount = (select totalamount from commandpayed where cpid = new.commandpayedid);

INSERT INTO `messagenotification`(`profileid`, `commandpayedid`, `message`, `viewstate`, `created`, `edited`) VALUES (new.producerid,new.commandpayedid,'You received new payment '+ new.commandpayedid+', please to check your account!', 0, now(), now());

INSERT INTO `invoice` (`commandpayedid`, `_status`, `amount`, `created`, `edited`) VALUES (new.commandpayedid, 'PAID', @amount, now(), now());


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `coupon_list`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `coupon_list` (
`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`phone` decimal(10,0)
,`proid` mediumint(9)
,`userid` varchar(80)
,`coid` mediumint(9)
,`connectorid` mediumint(9)
,`commandpayedid` mediumint(9)
,`ccreated` timestamp
,`cedited` timestamp
);

-- --------------------------------------------------------

--
-- Structure de la table `invoice`
--

CREATE TABLE `invoice` (
  `iid` mediumint(9) NOT NULL,
  `commandpayedid` mediumint(9) NOT NULL,
  `_status` varchar(20) NOT NULL,
  `amount` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `invoice`
--

INSERT INTO `invoice` (`iid`, `commandpayedid`, `_status`, `amount`, `created`, `edited`) VALUES
(1, 9, 'PAID', 25, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `invoice_list_from_cmdpayed`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `invoice_list_from_cmdpayed` (
`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`userid` varchar(80)
,`proid` mediumint(9)
,`phone` decimal(10,0)
,`cpid` mediumint(9)
,`totalamount` mediumint(9)
,`refcmd` varchar(200)
,`iid` mediumint(9)
,`istatus` varchar(20)
,`icreated` timestamp
);

-- --------------------------------------------------------

--
-- Structure de la table `messagenotification`
--

CREATE TABLE `messagenotification` (
  `mnid` mediumint(9) NOT NULL,
  `profileid` mediumint(9) NOT NULL,
  `commandpayedid` mediumint(9) NOT NULL,
  `message` text NOT NULL,
  `viewstate` tinyint(1) NOT NULL DEFAULT 0,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `messagenotification`
--

INSERT INTO `messagenotification` (`mnid`, `profileid`, `commandpayedid`, `message`, `viewstate`, `created`, `edited`) VALUES
(1, 1, 9, '9', 0, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

-- --------------------------------------------------------

--
-- Structure de la table `payment`
--

CREATE TABLE `payment` (
  `payid` mediumint(9) NOT NULL,
  `commandpayedid` mediumint(9) NOT NULL,
  `opname` varchar(50) NOT NULL,
  `senderid` varchar(50) NOT NULL,
  `receiverid` varchar(50) NOT NULL,
  `amount` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `payment`
--

INSERT INTO `payment` (`payid`, `commandpayedid`, `opname`, `senderid`, `receiverid`, `amount`, `created`, `edited`) VALUES
(44, 9, 'MTN', '154799566', '1545786315', 25, '2022-08-11 21:53:54', '2022-08-11 21:53:54');

--
-- Déclencheurs `payment`
--
DELIMITER $$
CREATE TRIGGER `update_accountstate` AFTER INSERT ON `payment` FOR EACH ROW BEGIN

set @producerid = (select proid from profile where phone = new.receiverid); 

INSERT INTO `accountstate`(`profileid`, `amount`, `created`, `edited`) VALUES (@producerid,new.amount,now(),now());
end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `product`
--

CREATE TABLE `product` (
  `pid` mediumint(9) NOT NULL,
  `brand` varchar(50) NOT NULL,
  `pname` varchar(50) NOT NULL,
  `category` mediumint(9) NOT NULL,
  `description` text DEFAULT NULL,
  `price` mediumint(9) DEFAULT 0,
  `year` mediumint(9) DEFAULT 2010,
  `qty` mediumint(9) DEFAULT 1,
  `imgs` text DEFAULT NULL,
  `ownerid` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `product`
--

INSERT INTO `product` (`pid`, `brand`, `pname`, `category`, `description`, `price`, `year`, `qty`, `imgs`, `ownerid`, `created`, `edited`) VALUES
(1, 'Le coq sportif', 'Indomitables lions 2021 jersey', 1, 'This jersey has been generated for the 2021 Chan.', 25, 2021, 1, 'cmrjersey2021.jpg', 1, '2022-08-11 13:46:39', '2022-08-11 21:28:30'),
(2, 'Le coq sportif', 'Indomitables lions jersey 2022', 1, 'This jersey has been generated for the 2022 Afcon.', 45, 2022, 55, 'cmrjersey2022.jpeg', 1, '2022-08-11 13:46:39', '2022-08-11 13:46:39'),
(3, 'Nike', 'Jordan 5', 2, 'Air Jordan for 89-90 NBA season', 120, 1989, 4, 'jordan5.jpg', 1, '2022-08-11 13:50:17', '2022-08-11 13:50:17');

-- --------------------------------------------------------

--
-- Structure de la table `productpayedfromcart`
--

CREATE TABLE `productpayedfromcart` (
  `ppfcid` mediumint(9) NOT NULL,
  `refcmd` varchar(200) NOT NULL,
  `productid` mediumint(9) NOT NULL,
  `qty` mediumint(9) NOT NULL,
  `amount` mediumint(9) DEFAULT 2010,
  `state` tinyint(1) NOT NULL DEFAULT 1,
  `img` text DEFAULT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `productpayedfromcart`
--

INSERT INTO `productpayedfromcart` (`ppfcid`, `refcmd`, `productid`, `qty`, `amount`, `state`, `img`, `created`, `edited`) VALUES
(19, '91032ad7bbcb6cf72875e8e8207dcfba80173f7c', 1, 1, 25, 1, 'cmrjersey2021.jpg', '2022-08-11 21:28:30', '2022-08-11 21:28:30');

--
-- Déclencheurs `productpayedfromcart`
--
DELIMITER $$
CREATE TRIGGER `set_product_qty_ad` AFTER DELETE ON `productpayedfromcart` FOR EACH ROW BEGIN

UPDATE `product` SET `qty`= old.qty, `edited`= now() WHERE `productid` = old.productid;

set @refcmd = old.refcmd;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `set_product_qty_ai` AFTER INSERT ON `productpayedfromcart` FOR EACH ROW BEGIN

UPDATE `product` SET `qty`= new.qty, `edited`= now() WHERE `pid` = new.productid;

set @refcmd = new.refcmd;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `set_product_qty_au` AFTER UPDATE ON `productpayedfromcart` FOR EACH ROW BEGIN

UPDATE `product` SET `qty`= new.qty, `edited`= now() WHERE `pid` = new.productid;

set @refcmd = new.refcmd;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `product_list_from_cmdpayed`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `product_list_from_cmdpayed` (
`cpid` mediumint(9)
,`consumerid` mediumint(9)
,`totalamount` mediumint(9)
,`cprefcmd` varchar(200)
,`_status` varchar(20)
,`created` timestamp
,`pid` mediumint(9)
,`pname` varchar(50)
,`description` text
,`ppfcid` mediumint(9)
,`amount` mediumint(9)
,`pqty` mediumint(9)
);

-- --------------------------------------------------------

--
-- Structure de la table `profile`
--

CREATE TABLE `profile` (
  `proid` mediumint(9) NOT NULL,
  `firstname` varchar(80) NOT NULL,
  `lastname` varchar(80) NOT NULL,
  `fullname` varchar(80) DEFAULT NULL,
  `gender` varchar(20) NOT NULL,
  `userid` varchar(80) NOT NULL,
  `phone` decimal(10,0) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `country` varchar(40) DEFAULT NULL,
  `imgUrl` varchar(200) DEFAULT NULL,
  `location` varchar(40) DEFAULT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `profile`
--

INSERT INTO `profile` (`proid`, `firstname`, `lastname`, `fullname`, `gender`, `userid`, `phone`, `city`, `country`, `imgUrl`, `location`, `created`, `edited`) VALUES
(1, 'Vince', 'Bear', 'Vince Bear', 'male', 'sportstore', '124547565', 'Douala', 'Cameroon', NULL, 'Akwa', '2022-08-11 14:02:15', '2022-08-11 14:02:15'),
(2, 'John', 'Doe', 'John Doe', 'male', 'jdoe', '154799566', 'Douala', 'Cameroon', NULL, 'Deido', '2022-08-11 14:02:15', '2022-08-11 14:02:15'),
(3, 'Adam', 'Kovici', 'Adam Kovici', 'male', 'kovich', '4897546678', 'Yaounde', 'Cameroon', NULL, 'Nlonkak', '2022-08-11 14:02:15', '2022-08-11 14:02:15'),
(4, 'Demi', 'Kameni', 'Demi Kameni', 'male', 'kamdem', '156489965', 'Douala', 'Cameroon', NULL, 'Carrefour Zachman', '2022-08-11 14:02:15', '2022-08-11 14:02:15'),
(5, 'Kelvin', 'Wazer', 'Kelvin Wazer', 'male', 'wazer', '1545786315', 'Douala', 'Cameroon', NULL, 'Bonanjo', '2022-08-11 14:02:15', '2022-08-11 14:02:15'),
(6, 'Vinyl', 'Caldone', 'Vinyl Caldone', 'male', 'calvin', '416878561', 'Douala', 'Cameroon', NULL, 'Bonaberi', '2022-08-11 14:02:15', '2022-08-11 14:02:15');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `profile_producer`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `profile_producer` (
`proid` mediumint(9)
,`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`phone` decimal(10,0)
,`username` varchar(80)
,`email` varchar(80)
,`roleid` mediumint(9)
,`role_name` varchar(20)
);

-- --------------------------------------------------------

--
-- Structure de la table `role`
--

CREATE TABLE `role` (
  `id` mediumint(9) NOT NULL,
  `role_name` varchar(20) NOT NULL,
  `description` text DEFAULT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `role`
--

INSERT INTO `role` (`id`, `role_name`, `description`, `created`, `edited`) VALUES
(1, 'producer', 'User allowed to updated all the contents', '2020-09-07 09:17:42', NULL),
(2, 'consumer', 'User allowed to update specific contnets', NULL, NULL),
(3, 'shipper', 'User allowed to updated all the contents', '2020-09-07 09:17:42', NULL),
(4, 'connector', 'User allowed to update specific contnets', NULL, NULL),
(5, 'Super admin', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `shipper_list`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `shipper_list` (
`proid` mediumint(9)
,`username` varchar(80)
,`roleid` mediumint(9)
);

-- --------------------------------------------------------

--
-- Structure de la table `shipping`
--

CREATE TABLE `shipping` (
  `shid` mediumint(9) NOT NULL,
  `cmdpayedid` mediumint(9) NOT NULL,
  `transporterid` mediumint(9) NOT NULL,
  `_status` varchar(20) NOT NULL,
  `reason` text NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `shipping`
--

INSERT INTO `shipping` (`shid`, `cmdpayedid`, `transporterid`, `_status`, `reason`, `created`, `edited`) VALUES
(1, 9, 0, 'PENDING', '', '2022-08-11 21:53:54', '2022-08-11 21:53:54');

--
-- Déclencheurs `shipping`
--
DELIMITER $$
CREATE TRIGGER `transfer_with_setting_invoice` AFTER UPDATE ON `shipping` FOR EACH ROW BEGIN

  CALL transfer(new._status, new.transporterid, new.reason, new.cmdpayedid);

end
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `shipping_list`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `shipping_list` (
`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`userid` varchar(80)
,`proid` mediumint(9)
,`phone` decimal(10,0)
,`cpid` mediumint(9)
,`totalamount` mediumint(9)
,`shid` mediumint(9)
,`transporterid` mediumint(9)
,`reason` text
,`sstatus` varchar(20)
,`screated` timestamp
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `total_commission_amount`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `total_commission_amount` (
`fullname` varchar(80)
,`city` varchar(50)
,`country` varchar(40)
,`location` varchar(40)
,`userid` varchar(80)
,`proid` mediumint(9)
,`phone` decimal(10,0)
,`SUM(amount)` decimal(30,0)
);

-- --------------------------------------------------------

--
-- Structure de la table `transfer`
--

CREATE TABLE `transfer` (
  `tid` mediumint(9) NOT NULL,
  `payid` mediumint(9) NOT NULL,
  `profileid` mediumint(9) NOT NULL,
  `connectorid` mediumint(9) NOT NULL,
  `amount` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Structure de la table `user`
--

CREATE TABLE `user` (
  `username` varchar(80) NOT NULL,
  `email` varchar(80) NOT NULL,
  `password` varchar(20) NOT NULL,
  `token` varchar(20) DEFAULT NULL,
  `roleid` mediumint(9) NOT NULL,
  `created` timestamp NULL DEFAULT NULL,
  `edited` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `user`
--

INSERT INTO `user` (`username`, `email`, `password`, `token`, `roleid`, `created`, `edited`) VALUES
('calvin', 'calvin@kwazer.com', 'password', NULL, 3, '2022-08-11 13:59:18', '2022-08-11 13:59:18'),
('jdoe', 'jdoe@kwazer.com', 'password', NULL, 2, '2022-08-11 13:55:51', '2022-08-11 13:55:51'),
('kamdem', 'kamdem@kwazer.com', 'password', NULL, 3, '2022-08-11 13:59:18', '2022-08-11 13:59:18'),
('kovich', 'kovich@kwazer.com', 'password', NULL, 2, '2022-08-11 13:55:51', '2022-08-11 13:55:51'),
('sportstore', 'ss@kwazer.com', 'password', NULL, 1, '2022-08-11 13:55:51', '2022-08-11 13:55:51'),
('wazer', 'wazer@kwazer.com', 'password', NULL, 4, '2022-08-11 13:59:18', '2022-08-11 13:59:18');

-- --------------------------------------------------------

--
-- Structure de la vue `accountstate_list`
--
DROP TABLE IF EXISTS `accountstate_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `accountstate_list`  AS  select `p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`phone` AS `phone`,`p`.`proid` AS `proid`,`p`.`userid` AS `userid`,`a`.`amount` AS `amount`,`a`.`connectorid` AS `connectorid`,`a`.`astateid` AS `astateid` from (`profile` `p` join `accountstate` `a`) where `p`.`proid` = `a`.`profileid` ;

-- --------------------------------------------------------

--
-- Structure de la vue `coupon_list`
--
DROP TABLE IF EXISTS `coupon_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `coupon_list`  AS  select `p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`phone` AS `phone`,`p`.`proid` AS `proid`,`p`.`userid` AS `userid`,`co`.`coid` AS `coid`,`co`.`connectorid` AS `connectorid`,`co`.`commandpayedid` AS `commandpayedid`,`co`.`created` AS `ccreated`,`co`.`edited` AS `cedited` from (`profile` `p` join `coupon` `co`) where `p`.`proid` = `co`.`producerid` ;

-- --------------------------------------------------------

--
-- Structure de la vue `invoice_list_from_cmdpayed`
--
DROP TABLE IF EXISTS `invoice_list_from_cmdpayed`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `invoice_list_from_cmdpayed`  AS  select `p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`userid` AS `userid`,`p`.`proid` AS `proid`,`p`.`phone` AS `phone`,`cp`.`cpid` AS `cpid`,`cp`.`totalamount` AS `totalamount`,`cp`.`refcmd` AS `refcmd`,`i`.`iid` AS `iid`,`i`.`_status` AS `istatus`,`i`.`created` AS `icreated` from ((`profile` `p` join `commandpayed` `cp`) join `invoice` `i`) where `p`.`proid` = `cp`.`consumerid` and `cp`.`cpid` = `i`.`commandpayedid` ;

-- --------------------------------------------------------

--
-- Structure de la vue `product_list_from_cmdpayed`
--
DROP TABLE IF EXISTS `product_list_from_cmdpayed`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `product_list_from_cmdpayed`  AS  select `cp`.`cpid` AS `cpid`,`cp`.`consumerid` AS `consumerid`,`cp`.`totalamount` AS `totalamount`,`cp`.`refcmd` AS `cprefcmd`,`cp`.`_status` AS `_status`,`cp`.`created` AS `created`,`pr`.`pid` AS `pid`,`pr`.`pname` AS `pname`,`pr`.`description` AS `description`,`ppf`.`ppfcid` AS `ppfcid`,`ppf`.`amount` AS `amount`,`ppf`.`qty` AS `pqty` from ((`commandpayed` `cp` join `product` `pr`) join `productpayedfromcart` `ppf`) where `cp`.`refcmd` = `ppf`.`refcmd` and `ppf`.`productid` = `pr`.`pid` ;

-- --------------------------------------------------------

--
-- Structure de la vue `profile_producer`
--
DROP TABLE IF EXISTS `profile_producer`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `profile_producer`  AS  select `p`.`proid` AS `proid`,`p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`phone` AS `phone`,`u`.`username` AS `username`,`u`.`email` AS `email`,`u`.`roleid` AS `roleid`,`r`.`role_name` AS `role_name` from ((`profile` `p` join `user` `u`) join `role` `r`) where `p`.`userid` = `u`.`username` and `u`.`roleid` = `r`.`id` ;

-- --------------------------------------------------------

--
-- Structure de la vue `shipper_list`
--
DROP TABLE IF EXISTS `shipper_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shipper_list`  AS  select `p`.`proid` AS `proid`,`u`.`username` AS `username`,`u`.`roleid` AS `roleid` from (`profile` `p` join `user` `u`) where `p`.`userid` = `u`.`username` and `u`.`roleid` = 3 ;

-- --------------------------------------------------------

--
-- Structure de la vue `shipping_list`
--
DROP TABLE IF EXISTS `shipping_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shipping_list`  AS  select `p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`userid` AS `userid`,`p`.`proid` AS `proid`,`p`.`phone` AS `phone`,`cp`.`cpid` AS `cpid`,`cp`.`totalamount` AS `totalamount`,`sh`.`shid` AS `shid`,`sh`.`transporterid` AS `transporterid`,`sh`.`reason` AS `reason`,`sh`.`_status` AS `sstatus`,`sh`.`edited` AS `screated` from ((`profile` `p` join `commandpayed` `cp`) join `shipping` `sh`) where `p`.`proid` = `cp`.`producerid` and `cp`.`cpid` = `sh`.`cmdpayedid` ;

-- --------------------------------------------------------

--
-- Structure de la vue `total_commission_amount`
--
DROP TABLE IF EXISTS `total_commission_amount`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `total_commission_amount`  AS  select `p`.`fullname` AS `fullname`,`p`.`city` AS `city`,`p`.`country` AS `country`,`p`.`location` AS `location`,`p`.`userid` AS `userid`,`p`.`proid` AS `proid`,`p`.`phone` AS `phone`,sum(`c`.`amount`) AS `SUM(amount)` from (`profile` `p` join `commission` `c`) where `p`.`proid` = `c`.`profileid` ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `accountstate`
--
ALTER TABLE `accountstate`
  ADD PRIMARY KEY (`astateid`);

--
-- Index pour la table `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`caid`);

--
-- Index pour la table `commandpayed`
--
ALTER TABLE `commandpayed`
  ADD PRIMARY KEY (`cpid`),
  ADD UNIQUE KEY `refcmd` (`refcmd`);

--
-- Index pour la table `commission`
--
ALTER TABLE `commission`
  ADD PRIMARY KEY (`aid`);

--
-- Index pour la table `coupon`
--
ALTER TABLE `coupon`
  ADD PRIMARY KEY (`coid`);

--
-- Index pour la table `invoice`
--
ALTER TABLE `invoice`
  ADD PRIMARY KEY (`iid`);

--
-- Index pour la table `messagenotification`
--
ALTER TABLE `messagenotification`
  ADD PRIMARY KEY (`mnid`);

--
-- Index pour la table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`payid`),
  ADD KEY `commandpay_fkey` (`commandpayedid`);

--
-- Index pour la table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`pid`),
  ADD KEY `category_fkey` (`category`);

--
-- Index pour la table `productpayedfromcart`
--
ALTER TABLE `productpayedfromcart`
  ADD PRIMARY KEY (`ppfcid`);

--
-- Index pour la table `profile`
--
ALTER TABLE `profile`
  ADD PRIMARY KEY (`proid`);

--
-- Index pour la table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `shipping`
--
ALTER TABLE `shipping`
  ADD PRIMARY KEY (`shid`);

--
-- Index pour la table `transfer`
--
ALTER TABLE `transfer`
  ADD PRIMARY KEY (`tid`),
  ADD KEY `pay_fkey` (`payid`),
  ADD KEY `consumerproducer_fkey` (`profileid`),
  ADD KEY `connector_fkey` (`connectorid`);

--
-- Index pour la table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `accountstate`
--
ALTER TABLE `accountstate`
  MODIFY `astateid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `category`
--
ALTER TABLE `category`
  MODIFY `caid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `commandpayed`
--
ALTER TABLE `commandpayed`
  MODIFY `cpid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT pour la table `commission`
--
ALTER TABLE `commission`
  MODIFY `aid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `coupon`
--
ALTER TABLE `coupon`
  MODIFY `coid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `invoice`
--
ALTER TABLE `invoice`
  MODIFY `iid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `messagenotification`
--
ALTER TABLE `messagenotification`
  MODIFY `mnid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `payment`
--
ALTER TABLE `payment`
  MODIFY `payid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT pour la table `product`
--
ALTER TABLE `product`
  MODIFY `pid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `productpayedfromcart`
--
ALTER TABLE `productpayedfromcart`
  MODIFY `ppfcid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT pour la table `profile`
--
ALTER TABLE `profile`
  MODIFY `proid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `shipping`
--
ALTER TABLE `shipping`
  MODIFY `shid` mediumint(9) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `transfer`
--
ALTER TABLE `transfer`
  MODIFY `tid` mediumint(9) NOT NULL AUTO_INCREMENT;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `commandpay_fkey` FOREIGN KEY (`commandpayedid`) REFERENCES `commandpayed` (`cpid`);

--
-- Contraintes pour la table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `category_fkey` FOREIGN KEY (`category`) REFERENCES `category` (`caid`);

--
-- Contraintes pour la table `transfer`
--
ALTER TABLE `transfer`
  ADD CONSTRAINT `connector_fkey` FOREIGN KEY (`connectorid`) REFERENCES `profile` (`proid`),
  ADD CONSTRAINT `consumerproducer_fkey` FOREIGN KEY (`profileid`) REFERENCES `profile` (`proid`),
  ADD CONSTRAINT `pay_fkey` FOREIGN KEY (`payid`) REFERENCES `payment` (`payid`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
