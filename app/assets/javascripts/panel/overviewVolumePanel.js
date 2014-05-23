module.controller('OverviewVolumePanel', [
	'$scope', 'pageService', function ($scope, page) {
		$scope.refreshPanel = function () {
			$scope.enabled = angular.isObject($scope.volume);
		};

		$scope.isContributor = function (volumeAccess) {
			return volumeAccess.access && volumeAccess.access >= 3;
		};

		$scope.isShared = function (volumeAccess) {
			return [1, 2].indexOf(volumeAccess.access) > -1;
		};

		$scope.isFunding = function (volumeAccess) {
			return !!volumeAccess.funding;
		};

		$scope.shareMessage = function (volumeAccess) {
			return page.constants.message('access.' + page.constants.data.permission[volumeAccess.access].name, volumeAccess.party.name);
		};

		$scope.ageSummary = function (summary) {
			var age = page.$filter('age');
			var range = age(summary.agerange[0]);

			if (summary.agerange[0] != summary.agerange[1]) {
				range += ' - ' + age(summary.agerange[1]);
			}

			return page.constants.message('volume.ages', range, age(summary.agemean));
		};

		$scope.hasProps = function (volume, property) {
			if (!volume[property]) {
				return false;
			}

			var has = false;

			for (var prop in volume[property]) {
				if (volume[property].hasOwnProperty(prop)) {
					return true;
				}
			}

			return false;
		};

		$scope.primaryStudy = function () {
			var study;

			for (var cite in $scope.volume.citations) {
				if ($scope.volume.citations.hasOwnProperty(cite) && $scope.volume.citations[cite].study) {
					study = $scope.volume.citations[cite];
					break;
				}
			}

			if (!study || !study.url) {
				return;
			}

			return '<a href="' + page.$filter('handle')(study.url) + '" target="_blank">' + page.constants.message('volume.doi.primary.visit') + '</a>';
		};

		//

		$scope.editMode = false;

		var form;

		$scope.edit = function () {
			$scope.editMode = true;
			form = $scope.volumeEditForm;

			form.data = {
				name: $scope.volume.name,
				alias: $scope.volume.alias,
				body: $scope.volume.body
			};
		};

		$scope.save = function () {
			var volume = new page.models.Volume(form.data);

			volume.$save({
				id: $scope.volume.id
			}, function (res) {
				page.messages.add({
					body: page.constants.message('volume.edit.success'),
					type: 'green',
					countdown: 3000
				});

				angular.extend($scope.volume, res);
				$scope.editMode = false;
			}, function (res) {
				page.messages.addError({
					body: page.constants.message('volume.edit.error'),
					report: res
				});
			});
		};

		$scope.cancel = function () {
			$scope.editMode = false;
			form.data = {};
		};
	}
]);
