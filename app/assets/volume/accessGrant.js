'use strict';

app.directive('accessGrantForm', [
  '$timeout', 'constantService', 'modelService', 'messageService', 'displayService',
  function ($timeout, constants, models, messages, display) {
    var link = function ($scope) {
      var volume = $scope.volume;
      var access = $scope.access;
      var form = $scope.accessGrantForm;

      form.data = {
        individual: access.individual,
        extend: access.children === access.individual
      };
      if (!access.individual) {
        form.$setDirty();
        $timeout(function () {
          // hack! calling $validate() doesn't work!
          form['access-'+access.party.id+'-individual'].$setValidity('required', false);
        });
      }

      form.canGrantAccess = function (p) {
        return p == constants.permission.READ ||
          p == constants.permission.EDIT ||
          p == constants.permission.ADMIN ||
          models.Login.checkAccess(constants.permission.ADMIN);
      };

      //

      form.save = function () {
        messages.clear(form);
        form.data.children = form.data.extend ? form.data.individual : 0;

        volume.accessSave(access.party.id, form.data).then(function () {
          messages.add({
            body: constants.message('access.grant.save.success'),
            type: 'green',
            owner: form
          });

          delete access.new;
          form.$setPristine();
        }, function (res) {
          messages.addError({
            body: constants.message('access.grant.save.error'),
            report: res,
            owner: form
          });

          display.scrollTo(form.$element);
        });
      };

      form.remove = function () {
        messages.clear(form);
        if (access.new) {
          form.removeSuccessFn(access);
          return;
        }
        volume.accessRemove(access.party.id).then(function () {
          messages.add({
            body: constants.message('access.grant.remove.success'),
            type: 'green',
            owner: form
          });

          form.$setPristine();
          form.removeSuccessFn(access);
        }, function (res) {
          messages.addError({
            body: constants.message('access.grant.remove.error'),
            report: res,
            owner: form
          });
          display.scrollTo(form.$element);
        });
      };

      //

      $scope.$emit('accessGrantForm-init', form, $scope);
    };

    //

    return {
      restrict: 'E',
      templateUrl: 'volume/accessGrant.html',
      link: link
    };
  }
]);
