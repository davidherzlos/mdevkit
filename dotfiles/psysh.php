<?php

define('CLI_SCRIPT', true);

return [
    'commands' => [
        new \Psy\Command\ParseCommand,
    ],
    'defaultIncludes' => [
	    './moodle-psysh.php',
    ],
    'forceArrayIndexes' => true,
];
