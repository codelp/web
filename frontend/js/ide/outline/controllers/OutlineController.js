import App from '../../../base'
import OutlinePane from '../components/OutlinePane'
import { react2angular } from 'react2angular'

App.controller('OutlineController', function($scope, ide) {
  $scope.isTexFile = false
  $scope.outline = []

  $scope.$on('outline-manager:outline-changed', onOutlineChange)

  function onOutlineChange(e, outlineInfo) {
    $scope.$applyAsync(() => {
      $scope.isTexFile = outlineInfo.isTexFile
      $scope.outline = outlineInfo.outline
    })
  }

  $scope.jumpToLine = lineNo => {
    ide.outlineManager.jumpToLine(lineNo)
  }
})

// Wrap React component as Angular component. Only needed for "top-level" component
App.component(
  'outlinePane',
  react2angular(OutlinePane, ['outline', 'jumpToLine', 'isTexFile'])
)
