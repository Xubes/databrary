'use strict';

module.controller('party/login', [
  'pageService', function (page) {
    page.display.title = page.constants.message('page.title.login');
  }
]);