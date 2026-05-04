#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Reinforcement Learning for SAM Prompts \
  #text(size: 10pt)[May 4, 2026; CSCE 775]],
  abstract: [
    We benchmark point selection strategies for single-shot semantic segmentation under a shared frozen DINOv2 plus Segment Anything Model (SAM) pipeline on FSS-1000, comparing eleven heuristics, a behavioral-cloning policy, and a Proximal Policy Optimization (PPO) fine-tune. Under a unified action space, the strongest heuristic, similarity-weighted Farthest Point Sampling at $alpha = 0.75$, achives a $0.768$ mean IoU (mIoU) using 5 points ($N = 5$); behavioral cloning of a greedy oracle reaches $0.672$ mIoU; and two reinforcement-learning (RL) fine-tunes warm-started from the cloned policy reach $0.864$ mIoU at $N = 5$ and $0.866$ mIoU at $N = 10$, with improvements of $0.193$ and $0.281$ over the behavioral cloning approach. On the canonical FSS-1000 one-shot subset, the same policies reach $0.876$ and $0.875$, surpassing PerSAM and SegGPT and approaching Matcher, which relies on the same DINOv2 plus SAM backbone.
  ],
  authors: (
    (
      name: "J.C. Vaught",
      department: [Dept. of Mechanical Engineering],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
    (
      name: "Xeerak Muhammad",
      department: [Dept. of Computer Science],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
    (
      name: "Jacob Whisenant",
      department: [Dept. of Mechanical Engineering],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
  ),
  bibliography: none,
)

#figure(
  image("figures/representative_examples.pdf", width: 90%),
  caption: [Representative test-set masks with $N = 10$ on three FSS-1000 queries (rows) across four classes (columns). Yellow outlines mark the predicted SAM mask, cyan outlines mark the ground truth mask, and red dots mark the selected point-prompt positions $(x,y)$; per-image IoU is printed below each panel. The RL fine-tune is the only method that recovers a complete mask on every query, while Top-K argmax fails outright on the park bench class, similarity-weighted FPS fragments under domain difficulty, and BC collapses on park bench and coconut tasks when longer horizons are required to reach a satisfactory position.],
  placement: top,
  scope: "parent",
) <fig:representative_examples>

= Introduction

Single-shot models learn to perform a task from a single labeled example. Single-shot semantic segmentation reframes this as a support–query problem. Given one annotated support image of a class, the
model must segment every instance of that class in a new query image. The setting is attractive because it avoids the expensive per-class supervision that conventional segmentation networks require, and it aligns with how practitioners often operate in the wild, where a small number of reference annotations must generalize to unseen scenes.   Recent progress in self-supervised representation learning @oquab2023dinov2 and promptable segmentation @kirillov2023sam has made this regime increasingly within reach for the average practitioner. In particular, the combination of a frozen vision transformer for feature extraction and the Segment Anything Model (SAM) for mask decoding has emerged as a dominant template, because it decouples class-agnostic shape priors from semantic correspondence and requires no fine-tuning on the target domain.

The standard template for single-shot SAM-based segmentation involves three stages: 1) feature extraction via DINOv2, 2) similarity map computation, and 3) point prompt selection for SAM. DINOv2 embeds both support and query images into dense feature grids. The annotated support region is averaged to form a reference class embedding, which is compared to each query pixel via cosine similarity. Finally, $N$ point prompts are extracted from the similarity map and passed to SAM, which produces the final mask.

However, this reduction from a dense similarity map to a small discrete set of point prompts is an open design choice. The prior two stages have well-established closed-form definitions, but point selection has received little systematic attention in the literature.

The naive choice of selecting the $N$ pixels with the highest similarity scores tends to concentrate points on a single high-confidence interior region of the object, because the similarity surface is smooth and unimodal over that region. SAM then receives redundant prompts that provide little additional disambiguating information about object extent, boundaries, or the presence of multiple instances. The working hypothesis across much of the recent literature is that _spatial spread_, jointly with similarity magnitude, is what governs mask quality, and a variety of heuristics, including non-maximum suppression (NMS), Farthest Point Sampling (FPS), and clustering-based selectors, have been proposed in service of that intuition. Yet these strategies are typically introduced as components of larger systems and compared only incidentally, leaving the relative merits of the underlying selection rules poorly characterized.

#figure(
  image("figures/02_state_action.pdf", width: 90%),
  caption: [Policy state and action representation. The state $s_t$ is a nine-channel tensor at $37 times 37$ resolution (DINOv2 similarity map, projected query features, point-prompt-history mask, current SAM mask, three step-counter planes, two coordinate planes), and the policy emits a logit over the same $37 times 37$ grid with previous-point pixels masked out before sampling.],
  placement: top,
  scope: "parent",
) <fig:state_action>

We address this gap with a benchmark of eleven non-trained point selection strategies, a behavioral-cloning (BC) policy, and a reinforcement-learning (RL) fine-tune, all evaluated on FSS-1000 @li2020fss1000 over $N in {1, 2, 3, 5, 7, 10}$. All methods share an identical front-end and back-end, namely a DINOv2 ViT-L/14 encoder and a SAM ViT-H decoder, so that the only source of variation is from the $N$ prompt locations that are drawn from the shared similarity map. To remove a residual source of confound, we additionally quantize every selector's output to a shared $37 times 37$ grid before passing it to SAM, so that heuristic, imitation, and reinforcement-learning policies all operate in the same action space. Hyperparameters are tuned on a held-out validation split under a frozen-test protocol to avoid bias.

= Related Work

== Few-shot semantic segmentation

Few-shot semantic segmentation has been driven by a sequence of architectures that aggregate dense correspondences between a support image-mask pair and a query image. Early approaches such as PFENet @tian2020pfenet and HSNet @min2021hsnet rely on fixed CNN encoders and learned aggregation modules. BAM @lang2022bam reframes the problem by explicitly distinguishing base and meta classes. VAT @hong2022vat introduces a 4D Swin transformer for cost aggregation, and DCAMA @shi2022dcama and HDMNet @peng2023hdmnet refine dense cross-attention strategies. These methods reach strong mIoU on FSS-1000 by exploiting rich correspondence structure between support and query, but they require training on the few-shot task itself and assume the query mask can be regressed densely.

== Promptable segmentation foundation models

The emergence of SAM @kirillov2023sam and its sequel SAM2 @ravi2024sam2 has made one-shot segmentation tractable from a small number of point or box prompts, without requiring per-class fine-tuning. SegGPT @wang2023seggpt takes a different route by training a single model that conditions on an arbitrary in-context example. Matcher @liu2024matcher and PerSAM @zhang2023persam pair SAM with feature-matching strategies to enable training-free few-shot segmentation, and SANSA @torres2025sansa adapts SAM2 with a small trained adapter for the one-shot setting. These methods all consume some form of prompt or example, but vary widely in how much information they pass to the segmentation backbone.

== Click-prompt training and interactive segmentation

A separate line of work trains networks to produce or simulate point-prompts for interactive segmentation. RITM @sofiiuk2022ritm and SimpleClick @liu2023simpleclick train iteratively with simulated user point-clicks using error-region heuristics, and FocalClick @chen2022focalclick refines the click-budget regime. These methods operate in a fundamentally different setting from ours because the user (or simulator) provides the click sequence; the network is trained to consume point rather than to produce them. To our knowledge, the present work is the first systematic comparison of heuristic, imitation, and reward-driven point selection on a unified action space against a frozen SAM decoder, with the explicit goal of understanding how the prompt-selection rule alone affects downstream mask quality.

#figure(
  image("figures/03_policy_arch.pdf", width: 80%),
  caption: [Policy network architecture. Three convolutional blocks form a shared backbone over the nine-channel input. The actor head is a $1 times 1$ convolution producing $37 times 37$ logits, masked by previous-point-prompt pixels before sampling. The value head is a global-average pool followed by an MLP scalar baseline used by PPO's advantage estimator.],
  placement: top,
  scope: "parent",
) <fig:policy_arch>

= Method

== Pipeline and notation

We benchmark thirteen point selection strategies under a shared single-shot semantic segmentation pipeline. Each episode consists of a support image with a support binary mask and a query image whose ground-truth mask is held out for evaluation. A frozen DINOv2 ViT-L/14 encoder maps both images to dense patch features at $224 times 224$ resolution, and patch features are bilinearly upsampled to the input grid so that every pixel carries a feature vector. The support prototype $p in RR^d$ is obtained by masked average pooling of the support feature map under the support mask, and the query similarity map is the cosine similarity between $p$ and each query feature. We denote this map by $S in [0, 1]^(H times W)$, where $H = W = 224$. The map is precomputed once per episode and cached, so every selection strategy receives the same input and any differences in downstream segmentation are attributed to point selection.

Given a fixed budget of point-prompts ($N$), a selection strategy is a deterministic or stochastic function that returns a point set $cal(P)_N = {(x_i, y_i)}_(i=1)^(N)$ with $(x_i, y_i) in {1, dots, W} times {1, dots, H}$. The point set is passed to a frozen SAM ViT-H decoder, where every point is treated as a positive label and no negative labels or box prompts are supplied. The decoder returns a single binary mask that is compared against the ground truth mask. To make heuristic, imitation, and reinforcement-learning selectors directly comparable at the prompt level, every chosen pixel coordinate is quantized to the nearest center of a shared $37 times 37$ grid before being passed to SAM. The grid resolution arises naturally from the BC oracle's candidate set, defined on this grid for tractable training, and we apply the same quantization to every selection rule so that all methods operate in a single action space.

#figure(
  image("figures/01_rl_loop.pdf", width: 100%),
  caption: [Reinforcement-learning interaction loop. At each step the policy maps the multi-channel state to a $37 times 37$ logit, samples a discrete point cell, passes it to SAM, and receives a reward equal to the change in IoU between the new and previous mask; the episode terminates after $N$ points.],
  placement: top,
  scope: "parent",
) <fig:rl_loop>

== Heuristic selectors

We evaluate eleven non-trained selection rules. _Top-K argmax_ picks the $N$ pixels with the highest values of the similarity map ($S$). _Top-K with non-maximum suppression (Top-K NMS)_ iteratively appends the current $arg max$ of $S$ to point set ($cal(P)_N$) and then sets $S(x', y') = -infinity$ for every pixel within Euclidean radius $r$ of the chosen point; we use $r = 14$. _Farthest Point Sampling (FPS)_ seeds with the global $arg max$ of $S$ and iteratively appends the pixel that maximizes the minimum Euclidean distance to all previously chosen points. _Similarity-weighted FPS_ scores each candidate as $alpha dot S(x, y) + (1 - alpha) dot tilde(d)(x, y)$ with $alpha = 0.75$, where $tilde(d)$ is the normalized minimum distance to $cal(P)$. _Top-K to k-means_ takes the $K' = 256$ highest-similarity pixels, clusters them into $N$ groups via $k$-means, and returns the highest-similarity pixel per cluster. _Local-maxima peaks_ detects local maxima of $S$ subject to a minimum-separation constraint of six pixels and returns the top $N$. _Connected-component centers_ thresholds $S$ at $tau = 0.75$, extracts $8$-connected components, and selects the $arg max$ of $S$ within each component. _Mean-shift modes_ runs mean-shift on similarity-weighted pixel coordinates with bandwidth six and returns the top $N$ modes. _Quantile-spaced_ sorts pixels by similarity in descending order and picks at evenly spaced quantiles. _Similarity-weighted random_ samples $N$ points without replacement from the categorical distribution with probabilities $p(x, y) prop exp(S(x, y) \/ T)$ at $T = 0.05$. _Determinantal Point Process (DPP)_ samples $cal(P)_N$ from a $k$-DPP with quality scores $q_i = S(x_i, y_i)$ and a Gaussian diversity kernel of length-scale $ell = 18$.

== Behavioral-cloning policy

In addition to the eleven heuristics, we evaluate a learned policy trained by behavioral cloning (BC) on a greedy oracle. For each training episode, we discretize the $224 times 224$ query grid to a $37 times 37$ candidate grid and, for each candidate position $(x_c, y_c)$, query SAM under the prompt set $cal(P)_t union {(x_c, y_c)}$ and record the resulting IoU against the ground-truth mask. The oracle's $t$-th point is the candidate that maximizes this IoU. Because the oracle's first $k$ points are identical for any $N >= k$ by construction, a single $N = 10$ trajectory yields oracle labels for every smaller budget, and we cache trajectories per episode to memory so that the imitator never re-invokes SAM during training. On the FSS-1000 validation split this oracle reaches a mIoU $0.948$ at $N = 2$, $0.952$ at $N = 3$, $0.956$ at $N = 5$, and $0.955$ at $N = 10$, confirming that the $37 times 37$ grid resolution is not the bottleneck and that substantial headroom exists above the heuristics.

 The loss is a Gaussian-kernel-density formulation of cross-entropy in which the oracle target is rendered as a Gaussian heatmap with $sigma = 2$ grid cells, so that the gradient signal degrades gracefully near the correct cell rather than treating any non-exact prediction as equally wrong. We add an auxiliary IoU loss term that, on a sub-batch of training examples, decodes the policy's argmax point and computes IoU against the ground-truth mask, providing a small, IoU-aligned supervisory signal. To match the inference-time setting, where re-clicking an already-clicked cell is meaningless, we mask previously-clicked cells out of the policy's logit space at training time. #highlight(fill: rgb("#FFB6C1"))[We train one policy per budget $N in {2, 5, 10}$ on the FSS-1000 train classes, select checkpoints by full-validation rollout IoU on the $450$ validation episodes, and evaluate on the held-out test split using the same eval setup as the heuristic baselines.]

== Reinforcement-learning fine-tune

The behavioral-cloning policy provides a strong initialization, but its training signal is the oracle's point identity rather than SAM's mask quality. To align the optimization signal with the actual evaluation criterion, we additionally fine-tune the cloned policy with reinforcement learning using SAM's IoU as the per-step reward. The setting is naturally formulated as a finite-horizon Markov decision process (MDP), illustrated in @fig:rl_loop. The state at step $t$ is $s_t = (Q, S, C_t, M_(t-1))$, where $Q$ denotes the projected DINOv2 query features, $S$ is the cosine similarity map, $C_t$ is the binary click-history mask after $t-1$ placements, and $M_(t-1)$ is SAM's mask under the prior prompt set. The action $a_t$ is a discrete pixel on the same $37 times 37$ grid the BC oracle was defined on, which preserves warm-start consistency. The reward at step $t$ is the marginal IoU gain $r_t = "IoU"(M_t, M^*) - "IoU"(M_(t-1), M^*)$, where $M^*$ is the ground-truth mask.

We use proximal policy optimization (PPO) @schulman2017ppo with the categorical policy expressed as a softmax over the $37 times 37$ logit map produced by the BC network. A linear value head is appended to the same backbone, yielding the shared-backbone actor-critic architecture in @fig:policy_arch. The policy is initialized from the BC best checkpoint, and a Kullback-Leibler regularization term $beta dot "KL"(pi_theta || pi_("BC"))$ is added to the loss to anchor the fine-tune to the imitation prior; we initialize $beta = 0.1$ and decay it linearly to $0.01$ over the first quarter of training. The full warm-start-then-fine-tune pipeline is shown in @fig:training_pipeline. #highlight(fill: rgb("#FFB6C1"))[PPO collects rollouts from $32$ vectorized environments, computes generalized advantages @schulman2016gae, and updates the policy with a clipped surrogate objective regularized by the KL anchor to the frozen BC reference.]

#figure(
  image("figures/04_training_pipeline.pdf", width: 100%),
  caption: [BC warm-start to PPO fine-tuning. The actor weights are copied from the BC checkpoint and the value head is initialized fresh. PPO collects rollouts from $32$ vectorized environments, computes generalized advantages, and updates the policy with a clipped surrogate objective regularized by a KL anchor to the frozen BC reference.],
  placement: top,
  scope: "parent",
) <fig:training_pipeline>

#highlight(fill: rgb("#FFB6C1"))[We use standard PPO hyperparameters: clip $epsilon = 0.2$, GAE $lambda = 0.95$, $gamma = 1.0$, four update epochs per rollout, and an effective rollout batch of $32$ vectorized environments times episode length. Across one million environment steps, the KL anchor coefficient $beta$ decays linearly from $0.1$ to $0.01$, the entropy coefficient from $0.01$ to $0.001$, and the learning rate from $3 times 10^(-4)$ to zero. Early steps keep the policy ($pi_theta$) close to the BC reference; late steps relax the constraints and let the agent optimize the change in IoU directly.] SAM ViT-B is used during PPO training to reduce per-call cost; final test evaluation uses the same SAM ViT-H decoder used by every other method, keeping the comparison unbiased.

We report two RL fine-tune runs, both warm-started from the BC policy at the matching budget and trained for one million environment steps. The $N = 5$ run targets the budget at which heuristic methods peak; the $N = 10$ run targets the longer horizon at which heuristic and imitation policies exhibit their characteristic late-decline failure mode.

== Evaluation protocol

We evaluate on FSS-1000 under a class-disjoint split in which the validation and test class pools are entirely disjoint, and #highlight(fill: rgb("#FFB6C1"))[we sample $450$ episodes per split]. Each episode is a tuple consisting of a support image, its support binary mask, a query image, and a query ground-truth mask, with the support mask and query image drawn from the same class. Selection strategies are evaluated at point budgets of $N = {1, 2, 3, 5, 7, 10}$. We perform grid-search on the validaiton set to tune each hueristic with tunable hyperparameters. Once the heuristic is tuned we freeze the weights and run inference for the test split. For stochastic methods we average over five seeds; deterministic methods run once with $"seed" = 0$.

To position our pipeline against external few-shot segmentation methods, we additionally evaluate on a $66$-class subset of the canonical FSS-1000 one-shot benchmark @li2020fss1000 disjoint from our training set, yielding $660$ test episodes under the canonical $10$-queries-per-class protocol. External methods are re-evaluated on the same $660$-episode subset using their respective public eval scripts, with their mIoU and foreground-background IoU computed on identical inputs to ours. As a sanity check, we re-ran Matcher on the full canonical $240$-class test set and reproduced its originally reported mIoU of $0.872$. We report intersection-over-union (IoU) as the primary metric.

= Experiments

== FSS-1000 in-domain benchmark

#figure(
  caption: [Heuristic vs. trained vs. RL methods on FSS-1000 test ($450$ episodes per cell).],
  placement: top,
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [$N=1$], [$N=2$], [$N=5$], [$N=7$], [$N=10$],
    ),
    table.hline(),
    [Greedy Oracle], [0.920], [0.948], [0.956], [0.956], [0.955],
    table.hline(stroke: 0.4pt),
    [*PPO RL*], [--], [--], [*0.864*], [--], [*0.866*],
    [BC], [--], [0.634], [0.672], [--], [0.586],
    [FPS ($alpha = 0.75$)], [0.585], [0.699], [0.768], [0.756], [0.731],
    [Top-K argmax], [0.585], [0.579], [0.502], [0.445], [0.379],
    table.hline(),
  )
) <tab:test_results>

@tab:test_results and @fig:miou_vs_n report test-set mean IoU for all heuristics, the BC policy, and the RL fine-tune, evaluated at $N in {1, 2, 3, 5, 7, 10}$ on $450$ episodes per cell under the unified action space. @tab:heuristic_sweep in the appendix lists every heuristic at every budget for completeness. The picture separates into clean tiers. The strongest heuristic, similarity-weighted FPS at $alpha = 0.75$, reaches $0.768$ mIoU at $N = 5$ and stays above $0.73$ mIoU across $N in {3, 5, 7, 10}$. Top-K NMS, Top-K to k-means, and local-maxima peaks track within $0.05$ IoU of similarity-weighted FPS at every budget. A second tier composed of DPP, connected-component centers, and similarity-weighted random sits in the $0.65$ to $0.69$ range. Mean-shift modes and Top-K argmax form a weaker third tier, with Top-K argmax notably the only method whose IoU degrades monotonically and steeply with $N$, dropping $20.6$ IoU points from $N = 1$ to $N = 10$ as redundant nearby points confuse SAM's prompt encoder. Pure FPS and quantile-spaced are catastrophic failures, falling below $0.20$ IoU past $N = 1$ because they place points in low-similarity regions that lie off-object. Nine of the eleven heuristics report identical IoU at $N = 1$ ($0.585$), validating the implementation: with a single output point, all of these rules reduce to the argmax of the cosine-similarity map snapped to the nearest grid cell.

== Imitation policies

#figure(
  image("figures/miou_vs_n.pdf", width: 100%),
  caption: [Mean IoU on the FSS-1000 test set as a function of point budget $N$, under the unified $37 times 37$ action space. The RL fine-tune (Garnet triangles) sits well above every other method at both trained budgets. The four Tier-1 heuristics cluster within $0.05$ IoU of one another and peak at $N in {3, 5}$. Top-K argmax decays monotonically; pure FPS and quantile-spaced collapse past $N = 1$.],
  placement: top,
) <fig:miou_vs_n>

The BC policy reaches $0.634$ mIoU at $N = 2$, $0.672$ mIoU at $N = 5$, and $0.586$ mIoU at $N = 10$, narrowly underperforming the strongest heuristic at $N = 5$ by $0.096$ IoU. The cluster-spread metric on BC's test rollouts confirms that train-time masking behaves as intended at small budgets but loses its effect with large budgets: the mean pairwise point distance is $47.9$ pixels at $N = 2$ but contracts to $34.1$ pixels at $N = 10$, indicating that the policy still drifts back into spatially correlated regions across multiple steps even when immediate re-clicking is forbidden.

== Per-step trajectory analysis

#highlight(fill: rgb("#FFB6C1"))[@fig:per_step_n5 plots the per-step rollout IoU of BC and the PPO fine-tune at $N = 5$. The two curves diverge immediately. By step $2$, RL reaches $0.786$ mIoU while BC reaches $0.599$ mIoU, and the RL trajectory is already above the strongest non-trained baseline shown as the dashed reference line. By step $3$, RL is at $0.846$ mIoU while BC is at $0.636$ mIoU. The RL curve continues to rise through clicks $4$ and $5$ to its final value of $0.864$, while the BC curve climbs only to $0.672$ mIoU. The gap between the two trajectories at every step is at least $0.187$ IoU.

The longer-horizon picture in @fig:per_step_n10 is sharper still. The RL fine-tune at $N = 10$ rises from $0.554$ mIoU at step $1$ to $0.777$ mIoU at step $2$, $0.831$ mIoU at step $3$, $0.852$ at step $4$, $0.863$ mIoU at step $5$, and reaches $0.868$ mIoU at step $6$. From step $6$ onward, the trajectory sits on a flat plateau between $0.866$ mIoU and $0.869$ mIoU, with no sign of late decline. The BC curve on the same axes peaks at step $3$ ($0.645$ mIoU) and degrades through every subsequent step to $0.586$ mIoU at step $10$.] The plateau-and-decline shape is shared by every heuristic and by BC, suggesting that imitation alone cannot break a SAM-imposed ceiling. The RL trajectories' rise-then-plateau, sustained across both the short-horizon and long-horizon budgets, indicates that reward-driven training reshapes the per-step curve.

== Reinforcement-learning fine-tune

The best PPO checkpoint at $N = 5$ occurs at update #highlight(fill: rgb("#FFB6C1"))[$5{,}250$ of $6{,}250$ with validation rollout IoU $0.903$; the best checkpoint at $N = 10$ occurs at update $3{,}000$ of $3{,}125$ with validation rollout IoU $0.895$.] The mean pairwise point distance on test rollouts is $69.5$ pixels at $N = 5$ and $69.3$ pixels at $N = 10$, essentially identical across the two budgets, indicating that reward-driven training maintains the same wide point distribution as the budget grows rather than contracting toward a tight cluster as BC does ($34.1$ pixels at $N = 10$).

== Comparison to external few-shot segmentation methods

#highlight(fill: rgb("#FFB6C1"))[@tab:sota_comparison shows the results of our pipeline against four external one-shot segmentation methods on the $66$-class canonical-disjoint subset. The PPO fine-tune at $N = 5$ reaches $0.876$ mIoU on the canonical-disjoint subset, slightly higher than its performance on our in-domain test split ($0.864$). The PPO fine-tune at $N = 10$ reaches $0.875$ mIoU. Among the external methods, SANSA leads at $0.923$ mIoU and Matcher follows at $0.892$ mIoU. Our RL fine-tune surpasses SegGPT ($0.867$ mIoU) and PerSAM ($0.741$ mIoU) but trails the two strongest external methods.] The most informative single comparison is against Matcher, since the two methods share an identical DINOv2-L plus SAM-H backbone and differ only in how the SAM decoder is prompted: Matcher uses a training-free dense-correspondence prompting strategy that goes beyond the strict positive-point vocabulary, while our RL policy returns at most ten positive points. The $0.016$ mIoU gap between the two indicates that, on the same backbone and the same canonical test, a learned point selector with a strict $N <= 10$ point-prompt budget closely approaches the quality of a more expressive prompting strategy. The $0.047$ mIoU gap to SANSA is best read as the cost of restricting the action space to grid-quantized positive points rather than as a deficiency of the RL training procedure itself, since SANSA replaces the entire encoder backbone with SAM2 and adds a trained adapter network.




#figure(
  caption: [Comparison against external few-shot methods on the canonical FSS-1000 one-shot $66$-class disjoint subset ($660$ episodes).],
  table(
    columns: (auto, auto),
    align: (left, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [mean IoU],
    ),
    table.hline(),
    [SANSA (SAM2-Hiera-L + adapter) @torres2025sansa], [0.923],
    [Matcher (DINOv2-L + SAM-H, training-free) @liu2024matcher], [0.892],
    [SegGPT @wang2023seggpt], [0.867],
    [PerSAM @zhang2023persam], [0.741],
    table.hline(stroke: 0.4pt),
    [RL fine-tune (PPO, $N=5$)], [0.876],
    [RL fine-tune (PPO, $N=10$)], [0.875],
    table.hline(stroke: 0.4pt),
    [Sim-weighted FPS ($alpha=0.75$, $N=5$)], [0.762],
    [BC ($N=5$)], [0.641],
    [Top-K argmax ($N=5$)], [0.474],
    table.hline(),
  )
) <tab:sota_comparison>

The relative ordering among our methods is preserved on the canonical-disjoint subset. RL clears every heuristic by a wide margin. BC underperforms its in-domain numbers at the longer budgets ($-0.031$ at $N = 5$, $-0.030$ at $N = 10$) while RL slightly outperforms its in-domain numbers ($+0.012$ at $N = 5$, $+0.009$ at $N = 10$), suggesting that reward-driven policies are more robust to class-distribution shift than imitation policies trained from oracle points.

== Ablations

We report two ablations using existing data, each isolating one design choice.

=== Effect of warm-start initialization

The PPO fine-tune is warm-started from the BC best checkpoint and KL-anchored to that same reference policy. Without the warm start, the policy network and the value head would both be initialized from scratch, and the KL anchor would reduce to a regularizer toward a degenerate prior. The relevant comparison in our data is between the BC starting point ($0.672$ mIoU at $N = 5$) and the PPO converged checkpoint ($0.864$ mIoU at $N = 5$), demonstrating that PPO recovers an additional $0.193$ IoU starting from a non-degenerate prior. The KL anchor at $beta = 0.1$ decaying to $0.01$ keeps the policy close to the BC reference early in training, when the value-function estimate is still noisy and unconstrained gradient steps would be most likely to destroy the warm-start signal.

=== Effect of action-space discretization

The $37 times 37$ grid discretization is could be considered as an artificial constraint. Thus, we compare the heuristic numbers under the grid-snapped protocol against the same heuristics evaluated at full $224 times 224$ pixel resolution on our in-domain split. The strongest heuristic, similarity-weighted FPS at $alpha = 0.75$, scores $0.759$ mIoU at $N = 5$ at full resolution and $0.768$ at $N = 5$ under grid quantization, a shift of $+0.009$ IoU. The grid-snapping step slightly improves the heuristics on average because it enforces a minimum spacing between selected pixels, partially solving the redundant-points problem on its own. The Top-K argmax decay shape is preserved: at $N in {1, 2, 5}$, the full-resolution IoU sequence is $(0.594, 0.586, 0.499)$ versus $(0.585, 0.579, 0.502)$ under grid quantization. Thus , the win for RL is not an artifact of the discretization. The grid step alone fails to close the gap to $0.864$ mIoU that the RL policy reaches under the same protocol.

#figure(
  image("figures/per_step_n5.pdf", width: 100%),
  caption: [Per-step rollout IoU at $N = 5$ on FSS-1000 test ($450$ episodes), comparing BC (Atlantic squares) against the PPO RL fine-tune warm-started from BC (Garnet triangles). The RL trajectory rises monotonically across all five points and clears the strongest non-trained baseline (dashed reference at $0.768$) by step $2$, while BC stays below the baseline at every step.],
  placement: top,
) <fig:per_step_n5>

== Cross-domain smoke test

#highlight(fill: rgb("#FFB6C1"))[We additionally ran a small cross-domain smoke test on Kvasir-SEG, a polyp segmentation dataset from medical imaging. Ten random support-query image pairs were sampled, with no class-disjoint structure (the dataset has only the polyp class). The same DINOv2-L sim-map and SAM ViT-H decoder were used; the heuristic, BC, and RL policies were applied without retraining. The strongest heuristic, similarity-weighted FPS at $N = 5$, reached only $0.149$ mean IoU on the ten pairs. The BC policy reached $0.357$ and the RL fine-tune reached $0.339$. All three values represent substantial degradation relative to FSS-1000, consistent with significant out-of-distribution shift from natural-image few-shot data to medical imagery. The heuristic crashes hardest because it relies entirely on the DINOv2 cosine similarity map, which itself degrades under domain shift; the learned policies (BC and RL), which take richer DINOv2 query features as additional input, degrade more gracefully but show no clear RL-over-BC advantage in this OOD setting.] 

== Representative examples

 #highlight(fill: rgb("#FFB6C1"))[The visual contrast confirms the quantitative story of @tab:test_results: the RL fine-tune is consistently competitive, BC has individual-episode failure modes at long horizons, and heuristics depend heavily on the scene.]

== Inference cost

#highlight(fill: rgb("#FFB6C1"))[Wall-clock cost is not the limiting factor for any of the strategies considered. Most heuristic methods run in under thirty milliseconds per call on a single GPU at the resolutions used here. The slowest heuristic case is the DPP with $ell = 18$ at $N = 10$, which reaches roughly forty-five milliseconds because of the eigendecomposition of its kernel. The fastest are Top-K argmax and quantile-spaced selection at approximately seven milliseconds. The BC and RL policies' per-step inference cost is dominated by the SAM decoder call itself; the policy network's contribution is a small additional CNN forward pass that runs in single-digit milliseconds.]

= Discussion

== Imitation hits a ceiling, reward breaks it

The clearest empirical finding of this work is the contrast between the per-step trajectory shapes of imitation and reward-driven policies. #highlight(fill: rgb("#FFB6C1"))[The behavior of Top-K argmax is the cleanest diagnostic: its mean IoU falls monotonically from $0.585$ at $N = 1$ to $0.379$ at $N = 10$, a drop of $20.6$ points across the budget range. The mechanism is geometric. Confidence-only selection draws its top points from a tight neighborhood around the global similarity maximum, and adding more such points does not enrich the prompt set so much as reinforce a single locus. SAM's prompt encoder is designed to consume each click as an additional disambiguating constraint on the latent mask, but redundant clicks at essentially the same spatial location carry no new disambiguation.] The four Tier-1 heuristics, which enforce spatial separation in different ways, all converge to within $0.05$ IoU at their respective peaks, suggesting that what SAM wants from its prompt set is decorrelation rather than any specific separation rule.

The behavioral-cloning policy provides a more interesting case. The greedy oracle that BC imitates is itself SAM-aware, in the sense that each oracle click is selected by maximizing IoU under SAM. Yet a policy trained to clone the oracle's click identities does not match the oracle's per-step trajectory. The cloned policy reproduces a pattern of plateau and decline rather than the oracle's continued ascent, peaking at click step $3$ at $N = 10$ and degrading thereafter. Imitation alone, even of a strong oracle, appears to inherit the heuristic-style ceiling rather than break through it.

The plateau-and-decline shape that bounds the heuristic family and the imitation policy is broken cleanly by reward-driven training. The operative difference is the alignment of the optimization signal. Imitation forces the policy to commit to the specific cells the oracle chose at each step, which is brittle on the test distribution; reward-driven training lets the policy choose any cell whose click happens to improve SAM's mask, and over many gradient steps that flexibility lets the policy discover click sequences whose joint information content exceeds anything any single oracle trajectory exhibits.

== Spatial spread, similarity floor, and action-space effects


#highlight(fill: rgb("#FFB6C1"))[The catastrophic failures of pure FPS and quantile-spaced selection sharpen this picture from the opposite direction. Both collapse below $0.20$ mean IoU past $N = 1$. After the first seed, pure FPS optimizes spatial distance with no regard for feature similarity, and on the small objects typical of FSS-1000 _far from chosen points_ usually means _outside the object_. SAM treats every click as a positive label, so it grows the mask outward to encompass the resulting background clicks. Quantile-spaced selection has the same defect by construction.] The general lesson is that any selector must enforce a similarity floor: every chosen point must lie in a region whose feature similarity is consistent with the support prototype, regardless of whether the rule is heuristic or learned.

The cluster-spread metric tells a complementary story for the learned policies. The mean pairwise click distance under RL is $69.5$ pixels at $N = 5$ and $69.3$ pixels at $N = 10$, essentially invariant across budgets. Under BC, the same metric contracts from $47.9$ pixels at $N = 2$ to $34.1$ pixels at $N = 10$, indicating that the imitation policy gradually re-introduces redundancy as the budget grows even when train-time masking explicitly penalizes immediate re-clicking. Reward-driven training discovers a budget-aware placement strategy; imitation discovers a fixed pattern that fails to use the longer horizon productively. The action-space ablation confirms this is not a discretization artifact: the heuristic numbers shift by less than $0.01$ IoU when the same selectors are evaluated under the unified $37 times 37$ grid versus full pixel resolution.

== Limitations and future work <sec:limitations>

Several caveats temper these conclusions. The benchmark was conducted on FSS-1000 alone, and the cross-domain smoke test on Kvasir-SEG suggests that all three method classes degrade substantially under medical-domain shift, with the heuristic family degrading hardest because of similarity-map degradation. We leave full medical-domain evaluation, including potentially domain-adapted features and proper episode protocols, to future work. All clicks in this study were treated as positive labels; neither negative-click prompts nor bounding-box prompts were explored, although both are first-class citizens in SAM's prompt vocabulary. Extending the policy's action space to include negative clicks is a particularly natural next step because negative clicks are the standard way to correct over-segmentation, and the present action space cannot issue them. The class-disjoint split rules out within-class memorization but does not probe cross-domain generalization at scale; a multi-dataset evaluation including Pascal-$5^i$ and COCO-$20^i$ would strengthen the headline claim. Finally, we report a single PPO seed per budget; multi-seed stability and the dependence on warm-start quality remain to be characterized.

= Conclusion

#figure(
  image("figures/per_step_n10.pdf", width: 100%),
  caption: [Per-step rollout IoU at $N = 10$ on FSS-1000 test, comparing BC against the RL fine-tune at $N = 10$. BC peaks at point $3$ ($0.645$) and declines monotonically through step $10$ ($0.586$ mIoU); RL rises sharply through step $6$ and then sits on a flat plateau between $0.866$ and $0.869$ mIoU through step $10$, sustaining its peak quality across the entire long-horizon budget.],
  placement: top,
) <fig:per_step_n10>

#highlight(fill: rgb("#FFB6C1"))[We presented a controlled comparison of point selection strategies for single-shot semantic segmentation under a shared DINOv2 and SAM pipeline on FSS-1000, with all selectors operating in a unified $37 times 37$ action space so that heuristic, imitation, and reinforcement-learning methods are directly comparable at the prompt level, and we additionally benchmarked the best of these methods against four external few-shot segmentation systems on the canonical FSS-1000 one-shot test protocol restricted to a $66$-class subset disjoint from our training set.]  The reinforcement-learning policies rise sharply through their first six clicks and then sit on a high plateau, breaking the plateau-and-decline shape that every other method exhibits. The empirical claim of the paper is that imitation alone cannot break the SAM-imposed ceiling that bounds the heuristic family, but that aligning the optimization signal with SAM's actual mask quality, via reinforcement learning warm-started from a behavioral-cloning prior, can.

#pagebreak()

#bibliography("refs.yaml", style: "ieee")

#pagebreak()

#set page(columns: 1)
#set heading(numbering: "A.")
#counter(heading).update(0)

= Appendix <appendix:heuristic-sweep>

#figure(
  caption: [Full heuristic sweep on FSS-1000 test ($450$ episodes per cell), under the unified action space. Frozen-best hyperparameters per method.],
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [$N=1$], [$N=2$], [$N=3$], [$N=5$], [$N=7$], [$N=10$],
    ),
    table.hline(),
    [Sim-weighted FPS ($alpha=0.75$)], [0.585], [0.699], [0.741], [0.768], [0.756], [0.731],
    [Top-K + NMS ($r=14$)], [0.585], [0.663], [0.717], [0.732], [0.732], [0.712],
    [Top-K to k-means ($K'=256$)], [0.585], [0.702], [0.730], [0.718], [0.677], [0.628],
    [Local-maxima peaks (sep $=6$)], [0.585], [0.679], [0.723], [0.732], [0.688], [0.631],
    table.hline(stroke: 0.4pt),
    [DPP ($ell=18$)], [0.577], [0.657], [0.690], [0.681], [0.674], [0.649],
    [Connected-component centers ($tau=0.75$)], [0.585], [0.632], [0.653], [0.619], [0.593], [0.547],
    [Sim-weighted random ($T=0.05$)], [0.451], [0.589], [0.642], [0.646], [0.674], [0.668],
    [Mean-shift modes (bw $=6$)], [0.602], [0.642], [0.620], [0.556], [0.512], [0.460],
    [Top-K argmax], [0.585], [0.579], [0.571], [0.502], [0.445], [0.379],
    table.hline(stroke: 0.4pt),
    [Quantile-spaced], [0.585], [0.137], [0.092], [0.077], [0.077], [0.077],
    [Farthest Point Sampling], [0.585], [0.169], [0.062], [0.050], [0.043], [0.048],
    table.hline(),
  )
) <tab:heuristic_sweep>
