yq -V
export PATH=$PWD/tools:$PATH
which yq
yq -V


APP_CHART_NAME=`echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
IMAGE_TAG=`echo ${GITHUB_REF} | awk -F "/" '{print $3}'`
if [[ ${IMAGE_TAG} == v* ]]; then IMAGE_TAG=`echo ${IMAGE_TAG:1}`; fi

echo helm fetch ${APP_CHART_NAME}:${IMAGE_TAG} to env-${TES_ENV}

if [ "${TES_ENV}" == "" ]; then
    echo "skip ${GITHUB_JOB} "
    exit 1
fi

env=${TES_ENV}
TAG=${IMAGE_TAG}
cd env-${env} || ! echo ' No such file or directory env-${env}' || exit 0
helmv3 repo add meeraspace ${HELM_REPO} --username=${HELM_USER} --password=${HELM_PASSWORD}

if [ -f "./${APP_CHART_NAME}/values-${env}.yaml" ];then
  mkdir -p tmp
  cp -v "./${APP_CHART_NAME}/"values-*.yaml tmp/
  rm -rf "./${APP_CHART_NAME}"
  helmv3 fetch meeraspace/${APP_CHART_NAME} --untar --version ${TAG} || exit 1
  cp -v tmp/values-*.yaml "./${APP_CHART_NAME}/" && rm -rf ./tmp
else
  [ -d "./${APP_CHART_NAME}" ] && rm -rf "./${APP_CHART_NAME}"
  helmv3 fetch meeraspace/${APP_CHART_NAME} --untar --version ${TAG} || exit 1
  touch "${APP_CHART_NAME}/values-${env}.yaml"
fi

git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
# git diff
git add ./${APP_CHART_NAME}
git pull
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${TAG}_details:${CI_COMMIT_MESSAGE}"
# git commit -m "${{ github.event.inputs.APP_CHART_NAME }}/${{ github.event.inputs.release-version }} to ${{ github.event.inputs.env }}"
git push
## error: failed to push some refs to 'git@github.com:tespkg/tes_manifests.git',
## usually caused by another repository pushing
if [ $? == 1 ]; then
    git stash
    git pull -r
    git stash apply
    git push
fi
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${env}-${APP_CHART_NAME}\033[0m \n\n======================="          
