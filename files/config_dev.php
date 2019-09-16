<?php
$defaultConfig = require 'config.php';

return [
    'db' => array (
      'username' => '__DBUSERNAME__',
      'password' => '__DBPASSWORD__',
      'host' => '__HOSTNAME__',
      'port' => '__PORT__',
      'dbname' => '__DBNAME__',
    ),

    'front' => [
        'throwExceptions' => true,
        'showException' => true
    ],

    'phpsettings' => [
        'display_errors' => 1
    ],

    'template' => [
        'forceCompile' => true
    ],

    'csrfProtection' => [
        'frontend' => true,
        'backend' => true
    ],

    'httpcache' => [
        'debug' => true
    ],
];
